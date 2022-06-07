# Public Actions

## update-images

Updates images in a kustomization.yaml file using output from skaffold build.

An image mapping is required to match up the image name from skaffold yaml to 
the image to update in kustomize. 

By default, skaffold build is run to build the images and output tags
according to your config. If you want bypass `skaffold build`
you can pass build-json.

This action does not commit the changes back to the repo, that can be
accomplished by some other action.


Example:

```yaml
      - name: Build & Update Image
        uses: hack-edu/public-actions/update-images@main
        with:
          working-directory: kustomize/
          image-mapping: |
            placeholder-for-image: my-image$
```

`image-mapping` is a YAML mapping from the kustomize image name to a regular
expression that matches the image name from skaffold.

Given the above example and the following skaffold.yaml file:

```yaml
apiVersion: skaffold/v1beta1
kind: Config
metadata:
    name: example
build:
    artifacts:
    - image: my-repository/my-image
```

Will generate this update:

```shell
kustomize edit set image placeholder-for-image=my-repository/my-image:generate-tag@sha256:<hash>
```
