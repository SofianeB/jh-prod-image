### Build docker image for ECASLab/JupyterHub

This image is based on [base-notebook](https://github.com/jupyter/docker-stacks/tree/master/base-notebook), which is based on ubuntu and provides only basic functionalities for jupyter. 
It is customized to provides mor tools/configuration required by ECASLab. 

#### How to build?

```
docker build -t <name> .
```

<name> should be the same in ```jupyterhub_config.py```!
