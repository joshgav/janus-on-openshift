#! /usr/bin/env bash

this_dir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
root_dir=$(cd ${this_dir}/.. && pwd)
workspace_dir=$(cd ${root_dir}/.. && pwd)
if [[ -e "${root_dir}/.env" ]]; then source ${root_dir}/.env; fi
if [[ -e "${this_dir}/.env" ]]; then source ${this_dir}/.env; fi
source ${this_dir}/lib/kubernetes.sh

export bs_app_name=${1:-${BS_APP_NAME:-rhdh}}
export quay_user_name=${2:-${QUAY_USER_NAME:-${USER}}}
export openshift_ingress_domain=$(oc get ingresses.config.openshift.io cluster -ojson | jq -r .spec.domain)

export upstream_image_url=quay.io/rhdh/rhdh-hub-rhel9:next

export registry_hostname=${REGISTRY_HOSTNAME:-quay.io}
export image_url_path=${quay_user_name}/${bs_app_name}-backstage
export image_tag=latest
export image_url_full=${registry_hostname}/${image_url_path}:${image_tag}

ensure_namespace ${bs_app_name} true

if [[ "${REBUILD_IMAGE}" == "1" ]]; then
    echo "INFO: cloning build machinery"
    tmpdir=$(mktemp -d)
    git clone https://github.com/janus-idp/redhat-backstage-build ${tmpdir}

    echo "INFO: build & push ${image_url_full}"
    pushd ${workspace_dir}/backstage-showcase
        yarn install
        yarn tsc
    popd
    docker build --tag ${image_url_full} \
        --file ${tmpdir}/Dockerfile \
        ${workspace_dir}/backstage-showcase
    docker push ${image_url_full}
elif [[ "${COPY_IMAGE}" == "1" ]]; then
    skopeo copy docker://${upstream_image_url} docker://${image_url_full}
fi

## TODO: test further, fix image and avoid this
# oc adm policy add-scc-to-user --serviceaccount=default nonroot-v2
oc adm policy add-scc-to-user --serviceaccount=default privileged
oc adm policy add-cluster-role-to-user --serviceaccount=default view

echo "INFO: apply resources from ${this_dir}/base/*.yaml"
for file in $(ls ${this_dir}/base/*.yaml); do
    ## hack: exclude files that have been entirely commented out
    lines=$(cat ${file} | awk '/^[^#].*$/ {print}' | wc -l)
    if [[ ${lines} > 0 ]]; then
        cat ${file} | envsubst '${bs_app_name} ${ARGOCD_AUTH_TOKEN} ${GITHUB_TOKEN} ${QUAY_TOKEN} ${registry_hostname}' | kubectl apply -f -
    fi
done

## apply custom app-config.yaml from this dir
file_path=${this_dir}/app-config.yaml
if [[ -e "${file_path}" ]]; then
    echo "INFO: applying appconfig configmap from ${file_path}"
    kubectl delete configmap custom-backstage-app-config 2> /dev/null

    tmpfile=$(mktemp)
    cat "${file_path}" | envsubst '${bs_app_name} ${quay_user_name} ${openshift_ingress_domain} ${registry_hostname}' > ${tmpfile}
    kubectl create configmap custom-backstage-app-config \
        --from-file "$(basename ${file_path})=${tmpfile}"
else
    echo "INFO: no file found at ${file_path}"
fi

github_app_creds_path=${this_dir}/github-app-credentials.yaml
if [[ -e ${github_app_creds_path} ]]; then
    echo "INFO: applying github-app-credentials.yaml as a secret"
    kubectl delete secret github-app-credentials 2> /dev/null
    kubectl create secret generic github-app-credentials --from-file=${github_app_creds_path}
fi

oc get clusterrolebinding backstage-backend-k8s &> /dev/null
if [[ $? != 0 ]]; then
    oc create clusterrolebinding backstage-backend-k8s --clusterrole=backstage-k8s-plugin --serviceaccount=${bs_app_name}:default
fi
oc get clusterrolebinding backstage-backend-ocm &> /dev/null
if [[ $? != 0 ]]; then
    oc create clusterrolebinding backstage-backend-ocm --clusterrole=backstage-ocm-plugin --serviceaccount=${bs_app_name}:default
fi
oc get clusterrolebinding backstage-backend-tekton &> /dev/null
if [[ $? != 0 ]]; then
    oc create clusterrolebinding backstage-backend-tekton --clusterrole=backstage-tekton-plugin --serviceaccount=${bs_app_name}:default
fi

echo "INFO: helm upgrade --install"
ensure_helm_repo bitnami https://charts.bitnami.com/bitnami 1> /dev/null
ensure_helm_repo backstage https://backstage.github.io/charts 1> /dev/null
ensure_helm_repo janus https://janus-idp.github.io/helm-backstage 1> /dev/null

for file in $(ls ${this_dir}/chart-values/*.yaml.tpl); do
    cat "${file}" | envsubst '${bs_app_name} ${quay_user_name} ${openshift_ingress_domain} ${registry_hostname} ${image_url_path} ${image_tag}' > ${file%".tpl"}
    chart_values+=" --values ${file%.tpl}"
done

echo "INFO: using chart values flags: ${chart_values}"
helm upgrade --install ${bs_app_name} janus/backstage ${chart_values}

## HACK: patch out custom app-config installed by Janus intermediate chart
oc patch configmap ${bs_app_name}-backstage-app-config -p "{\"data\": { \"app-config.yaml\": \"{}\" }}"

oc rollout restart deployment ${bs_app_name}-backstage

echo "INFO: Visit your Backstage instance at https://backstage-${bs_app_name}.${openshift_ingress_domain}/"
