# Kubernetes Securing Cluster

## Authorizing Requests 
### Types of Authorizations 
1. Node : Athorization is use for perticular perpose to grant permissions to kubelets baded on pods they are scheduled to run. 
1. ABAC (Attribute-based access control) is based on attributes combined with policies.
2. Webhooks : used for event notifications through HTTP POST request.
3. RBAC (Role-based access control): which grants or denies access through resources based on requester roles or groups.  

## 1. Creareting Cluster with Initial Config
1. Start minikube: ` $ minikube start`
2. Configure Current Context 
   ```
   $ kubectl config current-context
   ```
3. Deploy the go-demo-2 Application
   ```
    kubectl create -f go-demo-2.yml --record --save-config
   ```

## 2. Creating Users in Kubernetes 
1. To give cluster access to perticular user you need to create certifiucate for that user. (Note: verify that OpenSSL is installed on user machine ` $ openssl version`)
2. Creating Private key for user
   1. `$ mkdir keys` 
   2. `$ openssl genrsa -out keys/jdoe.key 2048`
3. Use private key to generate a certificate
   1. `$ openssl req -new -key keys/jdoe.key  -out keys/jdoe.csr -subj "/CN=jdoe/O=devs"`
   2. CN is the username and O represents organization.
4. Final certificate wil be creates using Cluster's certificate authotiry (CA). It is responsible for approving the request and generating the necessoury certificate for user to access the cluster.
5. If you are uisng Minikube the authority is already produced for user as part of cluster creation. It should be in direcory called .minikube in linux home folder.
   1. `$ ls -1 ~/.minikube/ca.*` 
   2. Output
        ```
        /home/user/.minikube/ca.crt
        /home/user/.minikube/ca.key
        /home/user/.minikube/ca.pem
        ```
6. Now generate final certificate by approving certificate sign request jdoe.csr 
   1.  `$ openssl x509 -req -in keys/jdoe.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out keys/jdoe.crt -days 365`
   2. Copy cluster's certificate authority to keys directory `$ cp ~/.minikube/ca.crt keys/ca.crt` 
   3. `$ ls -1 keys/`
   4. Output 
        ```
        ca.crt
        jdoe.crt
        jdoe.csr
        jdoe.key
        ```
7. User need to know address of cluster 
   1. `$ SERVER=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="minikube")].cluster.server}')`
   2. `$ echo $SERVER`
8. User have to set up cluster using above address and the certificate authority we send him (jdoe.crt, jdoe.key and ca.crt).
   1. `$ kubectl config set-cluster jdoe --certificate-authority keys/ca.crt --server $SERVER` 
   2. Output `Cluster "jdoe" set` 
9. Next user have to set the credentials using the certificate and the key we have created for him
   1.  `$ kubectl config set-credentials jdoe --client-certificate keys/jdoe.crt --client-key keys/jdoe.key`
   2.  Output `User "jdoe" set.`
10. Finally user will have to create a new context.
    1.  `$ kubectl config set-context jdoe --cluster jdoe --user jdoe`
    2.  Output : `Context "jdoe" created.`
    3.  `$ kubectl config use-context jdoe`
    4.  We create context jdoe that uses newly created cluster anf the user.
11. To made sure that we are using newly created context, lets look at the config
    1.  `$ kubectl config view` 
12. User jdoe acn access the cluster but connot retrive the list of pods. 
    1.  `$ kubectl get pods`
    2.  Output : `Error from server (Forbidden): pods is forbidden: User "jdoe" cannot list resource "pods" in API group "" in the namespace "default"`
    3.  User can check whether he is forbidden from seeing other types of objects
    4.  `$ kubectl get all`
13. Before  We change user permissions, lets look at components involved in the RBAC aothorisation process in next section.

## 3. Exploring RBAC 
#### 3.1 peeking Into Pre-defined cluster roles
1. `$ kubectl config use-context minikube`
2. `$ kubectl get all`
3. Lets check kubectl command can be use check whether we could perform an action if we would be specific user
4. `$ kubectl auth can-i get pods --as jdoe`
5. Output : `no`
6. Let's see if Roles and ClusterRoles are already configures in the cluster or on defalute namespace `$ kubectl get roles`
7. Output : `No resources found.` That means we dont have any Roles in default Namespace.
8. Lets check Cluster Roles `$ kubectl get clusterroles`
9. Output :
    ```
    NAME                                                                   AGE
    admin                                                                  129m
    cluster-admin                                                          129m
    edit                                                                   129m
    kubernetes-dashboard                                                   128m
    system:aggregate-to-admin                                              129m
    system:aggregate-to-edit                                               129m
    system:aggregate-to-view                                               129m
    system:auth-delegator                                                  129m
    system:basic-user                                                      129m
    system:certificates.k8s.io:certificatesigningrequests:nodeclient       129m
    system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   129m
    system:controller:attachdetach-controller                              129m
    system:controller:certificate-controller                               129m
    system:controller:clusterrole-aggregation-controller                   129m
    system:controller:cronjob-controller                                   129m
    system:controller:daemon-set-controller                                129m
    system:controller:deployment-controller                                129m
    system:controller:disruption-controller                                129m
    system:controller:endpoint-controller                                  129m
    system:controller:expand-controller                                    129m
    system:controller:generic-garbage-collector                            129m
    system:controller:horizontal-pod-autoscaler                            129m
    system:controller:job-controller                                       129m
    system:controller:namespace-controller                                 129m
    system:controller:node-controller                                      129m
    system:controller:persistent-volume-binder                             129m
    system:controller:pod-garbage-collector                                129m
    system:controller:pv-protection-controller                             129m
    system:controller:pvc-protection-controller                            129m
    system:controller:replicaset-controller                                129m
    system:controller:replication-controller                               129m
    system:controller:resourcequota-controller                             129m
    system:controller:route-controller                                     129m
    system:controller:service-account-controller                           129m
    system:controller:service-controller                                   129m
    system:controller:statefulset-controller                               129m
    system:controller:ttl-controller                                       129m
    system:coredns                                                         129m
    system:csi-external-attacher                                           129m
    system:csi-external-provisioner                                        129m
    system:discovery                                                       129m
    system:heapster                                                        129m
    system:kube-aggregator                                                 129m
    system:kube-controller-manager                                         129m
    system:kube-dns                                                        129m
    system:kube-scheduler                                                  129m
    system:kubelet-api-admin                                               129m
    system:nginx-ingress                                                   128m
    system:node                                                            129m
    system:node-bootstrapper                                               129m
    system:node-problem-detector                                           129m
    system:node-proxier                                                    129m
    system:persistent-volume-provisioner                                   129m
    system:public-info-viewer                                              129m
    system:volume-scheduler                                                129m
    view                                                                   129m
    ```
10. Lets take closer look at the Cluster Role with least permission which is `view`
    1.  `$ kubectl describe clusterrole view`
    2.  Output :
        ```
        Name:         view
        Labels:       kubernetes.io/bootstrapping=rbac-defaults
                    rbac.authorization.k8s.io/aggregate-to-edit=true
        Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
        PolicyRule:
        Resources                                    Non-Resource URLs  Resource Names  Verbs
        ---------                                    -----------------  --------------  -----
        bindings                                     []                 []              [get list watch]
        configmaps                                   []                 []              [get list watch]
        endpoints                                    []                 []              [get list watch]
        events                                       []                 []              [get list watch]
        limitranges                                  []                 []              [get list watch]
        namespaces/status                            []                 []              [get list watch]
        namespaces                                   []                 []              [get list watch]
        persistentvolumeclaims/status                []                 []              [get list watch]
        persistentvolumeclaims                       []                 []              [get list watch]
        pods/log                                     []                 []              [get list watch]
        pods/status                                  []                 []              [get list watch]
        pods                                         []                 []              [get list watch]
        replicationcontrollers/scale                 []                 []              [get list watch]
        replicationcontrollers/status                []                 []              [get list watch]
        replicationcontrollers                       []                 []              [get list watch]
        resourcequotas/status                        []                 []              [get list watch]
        resourcequotas                               []                 []              [get list watch]
        serviceaccounts                              []                 []              [get list watch]
        services/status                              []                 []              [get list watch]
        services                                     []                 []              [get list watch]
        controllerrevisions.apps                     []                 []              [get list watch]
        daemonsets.apps/status                       []                 []              [get list watch]
        daemonsets.apps                              []                 []              [get list watch]
        deployments.apps/scale                       []                 []              [get list watch]
        deployments.apps/status                      []                 []              [get list watch]
        deployments.apps                             []                 []              [get list watch]
        replicasets.apps/scale                       []                 []              [get list watch]
        replicasets.apps/status                      []                 []              [get list watch]
        replicasets.apps                             []                 []              [get list watch]
        statefulsets.apps/scale                      []                 []              [get list watch]
        statefulsets.apps/status                     []                 []              [get list watch]
        statefulsets.apps                            []                 []              [get list watch]
        horizontalpodautoscalers.autoscaling/status  []                 []              [get list watch]
        horizontalpodautoscalers.autoscaling         []                 []              [get list watch]
        cronjobs.batch/status                        []                 []              [get list watch]
        cronjobs.batch                               []                 []              [get list watch]
        jobs.batch/status                            []                 []              [get list watch]
        jobs.batch                                   []                 []              [get list watch]
        daemonsets.extensions/status                 []                 []              [get list watch]
        daemonsets.extensions                        []                 []              [get list watch]
        deployments.extensions/scale                 []                 []              [get list watch]
        deployments.extensions/status                []                 []              [get list watch]
        deployments.extensions                       []                 []              [get list watch]
        ingresses.extensions/status                  []                 []              [get list watch]
        ingresses.extensions                         []                 []              [get list watch]
        networkpolicies.extensions                   []                 []              [get list watch]
        replicasets.extensions/scale                 []                 []              [get list watch]
        replicasets.extensions/status                []                 []              [get list watch]
        replicasets.extensions                       []                 []              [get list watch]
        replicationcontrollers.extensions/scale      []                 []              [get list watch]
        ingresses.networking.k8s.io/status           []                 []              [get list watch]
        ingresses.networking.k8s.io                  []                 []              [get list watch]
        networkpolicies.networking.k8s.io            []                 []              [get list watch]
        poddisruptionbudgets.policy/status           []                 []              [get list watch]
        poddisruptionbudgets.policy                  []                 []              [get list watch]
        ```
11. Lets look at another predefined Cluster Role `edit`
    1.  `$ kubectl describe clusterrole edit`
    2.  Output 
        ```
        Name:         edit
        Labels:       kubernetes.io/bootstrapping=rbac-defaults
                    rbac.authorization.k8s.io/aggregate-to-admin=true
        Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
        PolicyRule:
        Resources                                    Non-Resource URLs  Resource Names  Verbs
        ---------                                    -----------------  --------------  -----
        configmaps                                   []                 []              [create delete deletecollection patch update get list watch]
        endpoints                                    []                 []              [create delete deletecollection patch update get list watch]
        persistentvolumeclaims                       []                 []              [create delete deletecollection patch update get list watch]
        pods                                         []                 []              [create delete deletecollection patch update get list watch]
        replicationcontrollers/scale                 []                 []              [create delete deletecollection patch update get list watch]
        replicationcontrollers                       []                 []              [create delete deletecollection patch update get list watch]
        services                                     []                 []              [create delete deletecollection patch update get list watch]
        daemonsets.apps                              []                 []              [create delete deletecollection patch update get list watch]
        deployments.apps/scale                       []                 []              [create delete deletecollection patch update get list watch]
        deployments.apps                             []                 []              [create delete deletecollection patch update get list watch]
        replicasets.apps/scale                       []                 []              [create delete deletecollection patch update get list watch]
        replicasets.apps                             []                 []              [create delete deletecollection patch update get list watch]
        statefulsets.apps/scale                      []                 []              [create delete deletecollection patch update get list watch]
        statefulsets.apps                            []                 []              [create delete deletecollection patch update get list watch]
        horizontalpodautoscalers.autoscaling         []                 []              [create delete deletecollection patch update get list watch]
        cronjobs.batch                               []                 []              [create delete deletecollection patch update get list watch]
        jobs.batch                                   []                 []              [create delete deletecollection patch update get list watch]
        daemonsets.extensions                        []                 []              [create delete deletecollection patch update get list watch]
        deployments.extensions/scale                 []                 []              [create delete deletecollection patch update get list watch]
        deployments.extensions                       []                 []              [create delete deletecollection patch update get list watch]
        ingresses.extensions                         []                 []              [create delete deletecollection patch update get list watch]
        networkpolicies.extensions                   []                 []              [create delete deletecollection patch update get list watch]
        replicasets.extensions/scale                 []                 []              [create delete deletecollection patch update get list watch]
        replicasets.extensions                       []                 []              [create delete deletecollection patch update get list watch]
        replicationcontrollers.extensions/scale      []                 []              [create delete deletecollection patch update get list watch]
        ingresses.networking.k8s.io                  []                 []              [create delete deletecollection patch update get list watch]
        networkpolicies.networking.k8s.io            []                 []              [create delete deletecollection patch update get list watch]
        poddisruptionbudgets.policy                  []                 []              [create delete deletecollection patch update get list watch]
        deployments.apps/rollback                    []                 []              [create delete deletecollection patch update]
        deployments.extensions/rollback              []                 []              [create delete deletecollection patch update]
        pods/attach                                  []                 []              [get list watch create delete deletecollection patch update]
        pods/exec                                    []                 []              [get list watch create delete deletecollection patch update]
        pods/portforward                             []                 []              [get list watch create delete deletecollection patch update]
        pods/proxy                                   []                 []              [get list watch create delete deletecollection patch update]
        secrets                                      []                 []              [get list watch create delete deletecollection patch update]
        services/proxy                               []                 []              [get list watch create delete deletecollection patch update]
        bindings                                     []                 []              [get list watch]
        events                                       []                 []              [get list watch]
        limitranges                                  []                 []              [get list watch]
        namespaces/status                            []                 []              [get list watch]
        namespaces                                   []                 []              [get list watch]
        persistentvolumeclaims/status                []                 []              [get list watch]
        pods/log                                     []                 []              [get list watch]
        pods/status                                  []                 []              [get list watch]
        replicationcontrollers/status                []                 []              [get list watch]
        resourcequotas/status                        []                 []              [get list watch]
        resourcequotas                               []                 []              [get list watch]
        services/status                              []                 []              [get list watch]
        controllerrevisions.apps                     []                 []              [get list watch]
        daemonsets.apps/status                       []                 []              [get list watch]
        deployments.apps/status                      []                 []              [get list watch]
        replicasets.apps/status                      []                 []              [get list watch]
        statefulsets.apps/status                     []                 []              [get list watch]
        horizontalpodautoscalers.autoscaling/status  []                 []              [get list watch]
        cronjobs.batch/status                        []                 []              [get list watch]
        jobs.batch/status                            []                 []              [get list watch]
        daemonsets.extensions/status                 []                 []              [get list watch]
        deployments.extensions/status                []                 []              [get list watch]
        ingresses.extensions/status                  []                 []              [get list watch]
        replicasets.extensions/status                []                 []              [get list watch]
        ingresses.networking.k8s.io/status           []                 []              [get list watch]
        poddisruptionbudgets.policy/status           []                 []              [get list watch]
        serviceaccounts                              []                 []              [impersonate create delete deletecollection patch update get list watch]
        ```
11. Lets look at another predefined Cluster Role `admin`
    1.  `$ kubectl describe clusterrole admin`
    2.  Output
        ```
        Name:         admin
        Labels:       kubernetes.io/bootstrapping=rbac-defaults
        Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
        PolicyRule:
        Resources                                       Non-Resource URLs  Resource Names  Verbs
        ---------                                       -----------------  --------------  -----
        rolebindings.rbac.authorization.k8s.io          []                 []              [create delete deletecollection get list patch update watch]
        roles.rbac.authorization.k8s.io                 []                 []              [create delete deletecollection get list patch update watch]
        configmaps                                      []                 []              [create delete deletecollection patch update get list watch]
        endpoints                                       []                 []              [create delete deletecollection patch update get list watch]
        persistentvolumeclaims                          []                 []              [create delete deletecollection patch update get list watch]
        pods                                            []                 []              [create delete deletecollection patch update get list watch]
        replicationcontrollers/scale                    []                 []              [create delete deletecollection patch update get list watch]
        replicationcontrollers                          []                 []              [create delete deletecollection patch update get list watch]
        services                                        []                 []              [create delete deletecollection patch update get list watch]
        daemonsets.apps                                 []                 []              [create delete deletecollection patch update get list watch]
        deployments.apps/scale                          []                 []              [create delete deletecollection patch update get list watch]
        deployments.apps                                []                 []              [create delete deletecollection patch update get list watch]
        replicasets.apps/scale                          []                 []              [create delete deletecollection patch update get list watch]
        replicasets.apps                                []                 []              [create delete deletecollection patch update get list watch]
        statefulsets.apps/scale                         []                 []              [create delete deletecollection patch update get list watch]
        statefulsets.apps                               []                 []              [create delete deletecollection patch update get list watch]
        horizontalpodautoscalers.autoscaling            []                 []              [create delete deletecollection patch update get list watch]
        cronjobs.batch                                  []                 []              [create delete deletecollection patch update get list watch]
        jobs.batch                                      []                 []              [create delete deletecollection patch update get list watch]
        daemonsets.extensions                           []                 []              [create delete deletecollection patch update get list watch]
        deployments.extensions/scale                    []                 []              [create delete deletecollection patch update get list watch]
        deployments.extensions                          []                 []              [create delete deletecollection patch update get list watch]
        ingresses.extensions                            []                 []              [create delete deletecollection patch update get list watch]
        networkpolicies.extensions                      []                 []              [create delete deletecollection patch update get list watch]
        replicasets.extensions/scale                    []                 []              [create delete deletecollection patch update get list watch]
        replicasets.extensions                          []                 []              [create delete deletecollection patch update get list watch]
        replicationcontrollers.extensions/scale         []                 []              [create delete deletecollection patch update get list watch]
        ingresses.networking.k8s.io                     []                 []              [create delete deletecollection patch update get list watch]
        networkpolicies.networking.k8s.io               []                 []              [create delete deletecollection patch update get list watch]
        poddisruptionbudgets.policy                     []                 []              [create delete deletecollection patch update get list watch]
        deployments.apps/rollback                       []                 []              [create delete deletecollection patch update]
        deployments.extensions/rollback                 []                 []              [create delete deletecollection patch update]
        localsubjectaccessreviews.authorization.k8s.io  []                 []              [create]
        pods/attach                                     []                 []              [get list watch create delete deletecollection patch update]
        pods/exec                                       []                 []              [get list watch create delete deletecollection patch update]
        pods/portforward                                []                 []              [get list watch create delete deletecollection patch update]
        pods/proxy                                      []                 []              [get list watch create delete deletecollection patch update]
        secrets                                         []                 []              [get list watch create delete deletecollection patch update]
        services/proxy                                  []                 []              [get list watch create delete deletecollection patch update]
        bindings                                        []                 []              [get list watch]
        events                                          []                 []              [get list watch]
        limitranges                                     []                 []              [get list watch]
        namespaces/status                               []                 []              [get list watch]
        namespaces                                      []                 []              [get list watch]
        persistentvolumeclaims/status                   []                 []              [get list watch]
        pods/log                                        []                 []              [get list watch]
        pods/status                                     []                 []              [get list watch]
        replicationcontrollers/status                   []                 []              [get list watch]
        resourcequotas/status                           []                 []              [get list watch]
        resourcequotas                                  []                 []              [get list watch]
        services/status                                 []                 []              [get list watch]
        controllerrevisions.apps                        []                 []              [get list watch]
        daemonsets.apps/status                          []                 []              [get list watch]
        deployments.apps/status                         []                 []              [get list watch]
        replicasets.apps/status                         []                 []              [get list watch]
        statefulsets.apps/status                        []                 []              [get list watch]
        horizontalpodautoscalers.autoscaling/status     []                 []              [get list watch]
        cronjobs.batch/status                           []                 []              [get list watch]
        jobs.batch/status                               []                 []              [get list watch]
        daemonsets.extensions/status                    []                 []              [get list watch]
        deployments.extensions/status                   []                 []              [get list watch]
        ingresses.extensions/status                     []                 []              [get list watch]
        replicasets.extensions/status                   []                 []              [get list watch]
        ingresses.networking.k8s.io/status              []                 []              [get list watch]
        poddisruptionbudgets.policy/status              []                 []              [get list watch]
        serviceaccounts                                 []                 []              [impersonate create delete deletecollection patch update get list watch]
        ```
13. Lets look at another predefined non-system Cluster Role `cluster-admin`
    1.  `$ kubectl describe clusterrole cluster-admin`
    2.  Output
        ```
        Name:         cluster-admin
        Labels:       kubernetes.io/bootstrapping=rbac-defaults
        Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
        PolicyRule:
        Resources  Non-Resource URLs  Resource Names  Verbs
        ---------  -----------------  --------------  -----
        *.*        []                 []              [*]
                    [*]                []              [*]
        ```
    3. `$ kubectl auth can-i "*" "*"`
    4. Output is : `yes`

## Creating Role Bindings And Cluster Role Bindings 
Role Binding bind a user or a group or a service accout to a role or cluster role.
1. Creating Role Dinding that will allow user(above) to view all the objects in the default namesapce.
   1. `$ kubectl create rolebinding jdoe --clusterrole view --user jdoe --namespace default --save-config` (current context should be minikube)
   2. `$ kubectl get rolebindings`
   3. Output : 
      ```
      NAME   AGE
      jdoe   42s
      ```
   4. Lets look at the details of newly created role binding `$ kubectl describe rolebinding jdoe`.
   5. Output :
      ```
        Name:         jdoe
        Labels:       <none>
        Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                        {"kind":"RoleBinding","apiVersion":"rbac.authorization.k8s.io/v1","metadata":{"name":"jdoe","creationTimestamp":null},"subjects":[{"kind":...
        Role:
        Kind:  ClusterRole
        Name:  view
        Subjects:
        Kind  Name  Namespace
        ----  ----  ---------
        User  jdoe  
      ```
    6. Remember role binding is always tied to a specific namespace. lets confirm that by using below command.
    7. `$ kubectl --namespace kube-system describe rolebinding jdoe`
    8. output: `Error from server (NotFound): rolebindings.rbac.authorization.k8s.io "jdoe" not found`     
    9. Lets verify that permission are set correcly.
    10. Lets check if the user (jdoe) can get all pods from the default Namespace.
    11. `$ kubectl auth can-i get pods --as jdoe`
    12. output : `yes`
    13. Now lets check if the user (jdoe) can get pods from all Namespace.
    14. `$ kubectl auth can-i get pods --as jdoe --all-namespaces`
    15. output `no`
    16. To give user a cluster-wide permissions, we have to delete rolebinding created in previous steps.
    17. `$ kubectl delete rolebinding jdoe`
    18. Output : `rolebinding.rbac.authorization.k8s.io "jdoe" deleted`
2. To Change Users (jdoe) view permissions so that they are applied accross the whole cluster. we will define ClusterRoleBinding resource in YAML file known as crb-view.yml.
   1. Creting role defined in crb-view.yml `$ kubectl create -f crb-view.yml --record --save-config`
   2. Output : `clusterrolebinding.rbac.authorization.k8s.io/view create`
   3. Lets validate that everything looks correct by describing the newly created role `$ kubectl describe clusterrolebinding view`.
   4. Output :
        ```
            Name:         view
            Labels:       <none>
            Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRoleBinding","metadata":{"annotations":{},"name":"view"},"roleRef":{"apiGroup"...
                        kubernetes.io/change-cause: kubectl create --filename=crb-view.yml --record=true --save-config=true
            Role:
            Kind:  ClusterRole
            Name:  view
            Subjects:
            Kind  Name  Namespace
            ----  ----  ---------
            User  jdoe
        ```
    5. Now lets check again if the user (jdoe) can get pods from all Namespace. `$ kubectl auth can-i get pods --as jdoe --all-namespaces`
    6. Output : `yes` confirming that jdoe can view the pods in all-namesapce.
3. User want to perform actions that will help them develop and test their application without affecting other users of the cluster. Such request from users provides an excellent opportunity to combine Namespase with Role Bindings. In this section we will create dev Namesapce and allow selected grop of users to do almost anything in it. 
   1. lets explore rd-dev.yml file to understand Namespace with role binding.
   2. Lets create new resource `$ kubectl create -f rb-dev.yml --record --save-config`
   3. Output :
        ```
        namespace/dev created
        rolebinding.rbac.authorization.k8s.io/dev created
        ```
   4. We can see that the Namespace dev and the RoleBinding is created. Now lets verify that the user jdoe can create and delete Deployemtnts using below cammands.
   5. `$ kubectl --namespace dev auth can-i create deployments --as jdoe`
   6. Output : `yes`
   7. `$ kubectl --namespace dev auth can-i delete deployments --as jdoe`
   8. Output : `yes` 
   9. The above output of both the commands confirm that user jdoe can perform create and delete actions with Deployments.
   10. Cluster-admin role covers all the permissions, but the user jdeo doen not icludes all resources nad verbs.
   11. `$ kubectl --namespace dev auth can-i "*" "*" --as jdoe`
   12. Output : `no`  which indicates there re still few opertions are forbidden to user jdoe.
   13. 