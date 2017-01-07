#FROM centos:latest
FROM centos/s2i-base-centos7

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

LABEL io.k8s.description="An open-source software library for Machine Intelligence" \
      io.k8s.display-name="Tensorflow 0.12" \
      io.openshift.expose-services="6006:http" \
      io.openshift.expose-services="8888:http" \
      io.openshift.tags="builder,python,python35,rh-python35,tensorflow"

#Update centos 
RUN yum update -y

#Install Dependencies
RUN yum groupinstall 'Development Tools' -y
RUN yum install -y \
        curl \
        freetype-devel \
        libpng12-devel \
        pkgconfig \
        python \
        python-devel \
        rsync \
        unzip \
        nss_wrapper \
        gettext \
        && \
        yum clean all -y

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        scipy \
        sklearn \
        Pillow \
        && \
    python -m ipykernel.kernelspec

# --- DO NOT EDIT OR DELETE BETWEEN THE LINES --- #
# These lines will be edited automatically by parameterized_docker_build.sh. #
# COPY _PIP_FILE_ /
# RUN pip --no-cache-dir install /_PIP_FILE_
# RUN rm -f /_PIP_FILE_

# Install TensorFlow CPU version from central repo
RUN pip --no-cache-dir install \
    http://storage.googleapis.com/tensorflow/linux/gpu/tensorflow-0.11.0rc0-cp27-none-linux_x86_64.whl
#http://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.0.0-cp27-none-linux_x86_64.whl
# --- ~ DO NOT EDIT OR DELETE BETWEEN THE LINES --- #

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH.
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

# Each language image can have 'contrib' a directory with extra files needed to
# run and build the applications.
COPY ./contrib/ /opt/app-root

# In order to drop the root user, we have to make some directories world
# writable as OpenShift default security model is to run the container under
# random UID.
RUN chown -R 1001:0 /opt/app-root && chmod -R og+rwx /opt/app-root

USER 1001

# RUN ln -s /usr/bin/python3 /usr/bin/python#

# Set up our notebook config.
COPY jupyter_notebook_config.py $HOME/.jupyter/

# Copy sample notebooks.
COPY notebooks /notebooks

# Jupyter has issues with being run directly:
#   https://github.com/ipython/ipython/issues/7062
# We just add a little wrapper script.
COPY run_jupyter.sh /


WORKDIR "/notebooks"

CMD ["/run_jupyter.sh"]
