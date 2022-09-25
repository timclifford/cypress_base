FROM cypress/base:16

RUN node -v
RUN npm -v

COPY . /app/

RUN npm install --save-dev cypress

RUN $(npm bin)/cypress verify
#RUN $(npm bin)/cypress install

ENTRYPOINT ["/node_modules/.bin/cypress"]
