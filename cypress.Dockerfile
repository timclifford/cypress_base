FROM cypress/base:14

RUN node -v
RUN npm -v

COPY . /app/

RUN npm install --save-dev cypress

RUN $(npm bin)/cypress verify
#RUN $(npm bin)/cypress install

ENTRYPOINT ["/node_modules/.bin/cypress"]
