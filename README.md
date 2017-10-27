# DEPRECATED - IBM DevOps Services Pipeline Extension for Docker Build

## Overview
--------
Provides extension point for IBM DevOps Services to build a docker container using the IBM Container Service docker build.  

## Prereqs 
- Project owner has configured IBM DevOps Services Project to deploy to IBM Bluemix including setting up space and organization 
- Project owner has added Pipeline Service and Container Service in IBM Bluemix

## Input 
- Project has a Dockerfile that can be built in the root of the directory 
- Project owners Bluemix token will be automatically provided by the pipeline to the extension point for deployment
- APPLICATION_NAME: name of the application 
- REGISTRY_URL: registry url set when enabling the Container Service in bluemix 
- VERSION_IMAGES: if set to true, each build will result in a uniquely tagged image.  If false will only tag image as :latest 
- MAX_IMAGES: maximin number of image versions to store in the registry 

## Output 
The output of the build step will be a new image stored in IBM container registry that is tagged base on the build number and latest 
- <registryurl>/<application_name>:<version> 
- <registryurl>/<application_name>:latest
 
## Feedback and help
The point of this project is to experiment, learn and get feedback.  We believe that a deployment pipeline for Docker containers maybe a valuable thing. However, we would like to hear from you and get your input. 

You can start a discussion and leave feedback right on this project! Go to track and plan (top Right) and create a work item.  

## References
- [IBM Bluemix](https://console.ng.bluemix.net/)
- [IBM Container Service](https://developer.ibm.com/bluemix/2014/12/04/ibm-containers-beta-docker/)
- [Introduction to containers and bluemix](https://www.youtube.com/watch?v=-fcMeHdjC2g)