# Docker demo underworld image

FROM ubuntu:latest

MAINTAINER Jerico Revote <jerico.revote@monash.edu>

USER root

# Local User
RUN useradd -m -s /bin/bash cerberus

# Compilers
RUN apt-get update && apt-get install -y gcc g++ gfortran && apt-get clean

# Utilities
RUN apt-get install -y vim screen wget curl aptitude mercurial git && apt-get clean

# Development Libraries
RUN apt-get install -y libpng12-dev libxml2-dev libhdf5-dev libgeos-dev libgeos++-dev libproj-dev libxslt1-dev libglu1-mesa-dev libgl1-mesa-dev libosmesa6-dev libosmesa6 libpetsc3.4.2-dev libcurl3-dev freeglut3-dev libgl2ps-dev libx11-dev python-dev python-pip libudunits2-dev libgrib-api-dev libfreetype6-dev libncurses-dev libgrib-api-tools && apt-get clean

# GDAL
RUN cd /tmp && \
    wget ftp://ftp.remotesensing.org/gdal/1.11.2/gdal-1.11.2.tar.gz && \
    tar xvzf gdal-1.11.2.tar.gz && \
    cd gdal-1.11.2 && \
    ./configure --with-python && \
    make && \
    make install

# IPython
RUN pip install "ipython[all]" terminado ipywidgets

# Prepare
USER cerberus
RUN ipython profile create
USER root
ADD profile_default /home/cerberus/.ipython/profile_default
ADD templates/ /srv/templates/
RUN chmod a+rX /srv/templates
RUN chown cerberus:cerberus /home/cerberus -R

# Expose our custom setup to the installed ipython (for mounting by nginx)
RUN mkdir -p /usr/local/lib/python2.7/dist-packages/IPython/html/static/custom/
RUN cp /home/cerberus/.ipython/profile_default/static/custom/* /usr/local/lib/python2.7/dist-packages/IPython/html/static/custom/

# NumPy
RUN pip install numpy

# Cython
RUN pip install cython

# Python Dependencies
RUN pip install rasterio obspy shapely fiona geopandas 
RUN pip install basemap --allow-external basemap --allow-unverified basemap
RUN pip install pyke --allow-external pyke --allow-unverified pyke
RUN pip install PIL --allow-external PIL --allow-unverified PIL

# Extra Kernels
RUN pip install bash_kernel

# Underworld
USER cerberus
RUN hg clone -b newInterface https://bitbucket.org/underworldproject/underworld2 /home/cerberus/underworld2 && \
    cd /home/cerberus/underworld2/libUnderworld && \
    ./configure.py && \
    ./scons.py

USER root
RUN chown -R cerberus:cerberus /home/cerberus

EXPOSE 8888

USER cerberus
ENV HOME /home/cerberus
ENV SHELL /bin/bash
ENV USER cerberus
ENV PYTHONPATH $HOME/underworld2:$PYTHONPATH
WORKDIR $HOME/underworld2/InputFiles

USER cerberus

# Convert notebooks to the current format
RUN find . -name '*.ipynb' -exec ipython nbconvert --to notebook {} --output {} \;
RUN find . -name '*.ipynb' -exec ipython trust {} \;

CMD ipython notebook
