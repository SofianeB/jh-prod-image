FROM centos:7

LABEL maintainer="Sofiane Bendoukha <bendoukha@dkrz.de>"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN yum -y update \
 && yum install -yq \
    wget \
    make \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    gcc

RUN yum -y groupinstall "Development tools"

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Install Tini
RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

ADD fix-permissions /usr/local/bin/fix-permissions
# Create jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    fix-permissions $HOME && \
    fix-permissions $CONDA_DIR

USER $NB_UID

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    fix-permissions /home/$NB_USER

# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION 4.4.10
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "bec6203dbb2f53011e974e9bf4d46e93 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Jupyter Notebook and Hub
RUN conda install --quiet --yes \
    'proj4' \
    'basemap=1.1.0=py36_4' \
    'notebook=5.4.*' \
    'jupyterhub=0.9.*' \
    'jupyterlab=0.32.*' && \
    conda clean -tipsy && \
    jupyter labextension install @jupyterlab/hub-extension@^0.8.1 && \
    npm cache clean --force && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

USER root

EXPOSE 8888
WORKDIR $HOME

# Install PyOphidia and matplotlib
RUN pip install --upgrade pip &&\
    pip install pyophidia &&\
    pip install matplotlib &&\
    pip install numpy

# Configure container startup
ENTRYPOINT ["tini", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER

RUN echo 'export OPH_TERM_PS1=yellow' >> ~/.bashrc
RUN echo 'export OPH_SERVER_HOST=ecas-server.dkrz.de' >> ~/.bashrc
RUN echo 'export OPH_SERVER_PORT=11732' >> ~/.bashrc
RUN echo 'export OPH_RESPONSE_BUFFER=6144' >> ~/.bashrc
RUN echo 'export OPH_WORKFLOW_AUTOVIEW=on' >> ~/.bashrc
RUN echo 'export OPH_TERM_IMGS=save' >> ~/.bashrc
RUN echo 'export DISPLAY=Localhost:10.0' >> ~/.bashrc
RUN echo 'export OPH_CWD=/home/jovyan/work/' >> ~/.bashrc

RUN echo 'if [ $(whoami) == jovyan ]; then oph_term; exit' >> ~/.bashrc

RUN echo 'fi' >> ~/.bashrc

ENV OPH_TERM_PS1=$OPH_TERM_PS1
ENV OPH_SERVER_HOST=$OPH_SERVER_HOST
ENV OPH_SERVER_PORT=$OPH_SERVER_PORT
ENV OPH_RESPONSE_BUFFER=$OPH_RESPONSE_BUFFER
ENV OPH_WORKFLOW_AUTOVIEW=$OPH_WORKFLOW_AUTOVIEW
ENV OPH_TERM_IMGS=$OPH_TERM_IMGS
ENV DISPLAY=$DISPLAY
ENV OPH_CWD=$OPH_CWD

RUN mkdir ~/.ipython/ && mkdir ~/.ipython/profile_default
COPY ipython_config.py /home/jovyan/.ipython/profile_default/ipython_config.py

RUN chown -R jovyan: /home/jovyan/work

WORKDIR /home/jovyan/work

RUN jupyter trust /home/jovyan/work/*.ipynb

WORKDIR /home/jovyan

ADD notebook-extensions /home/jovyan

RUN jupyter nbextension install calysto --user

RUN jupyter nbextension enable calysto/publish/main
