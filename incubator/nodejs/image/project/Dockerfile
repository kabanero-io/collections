# Install the app dependencies in a full Node docker image
FROM registry.access.redhat.com/ubi8/nodejs-10

USER root

# Install OS updates
RUN yum upgrade -y \
 && yum clean packages \
 && echo 'Finished installing dependencies'

# Install user-app dependencies
WORKDIR "/project/user-app"
COPY ./user-app/package*.json ./
RUN npm install --production

WORKDIR "/project/user-app"

ENV NODE_ENV production

# Need to work out what user to run node images under - TODO
# USER node

CMD ["npm", "start"]
