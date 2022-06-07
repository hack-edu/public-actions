# Public Actions

## update-images

Updates images in a kustomization.yaml file using output from skaffold build.

By default, skaffold build is run to build the images and output tags
according to your config. If you want bypass `skaffold build`
you can pass build-json.

This action does not commit the changes back to the repo, that can be
accomplished by some other action.
