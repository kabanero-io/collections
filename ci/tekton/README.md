
1. Deploy pipeline
    ```
    oc apply -f tekton/collections-build-task.yaml -n kabanero
    ```

1. Configure security constraints for service account
    ```
    oc adm policy add-scc-to-user anyuid -z kabanero-collections -n kabanero
    ```

1. Configure build
Update the `tekton/collections-build-task-run.yaml` file with your settings. If you are using GitHub Enterprise, create a secret following https://github.com/tektoncd/pipeline/blob/master/docs/auth.md#basic-authentication-git instructions and associate it with the `kabanero-collections` service account. For example:
    ```
    oc secrets link kabanero-collections basic-user-pass
    ```

1. Trigger build
    ```
    oc delete --ignore-not-found -f tekton/collections-build-task-run.yaml; sleep 5; oc apply -f tekton/collections-build-task-run.yaml
    ```
