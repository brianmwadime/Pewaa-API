![](http://www.pewaa.com/img/core-img/logo.png)
# Pewaa-API

## Table of Contents

* [Installation](#Installation)
* [Supported APIs](#supported-apis)
* [License](#license)
* [Contributing](#contributing)

# Installation

Installing Pewaa API is easy and straight-forward, but there are a few requirements you’ll need
to make sure your system has before you start.

## Requirements

You will need to install some stuff, if they are not yet installed in your machine:

* [Node.js (v4.3.2 or higher; LTS)](http://nodejs.org)
* [NPM (v3.5+; bundled with node.js installation package)](https://docs.npmjs.com/getting-started/installing-node#updating-npm)

If you've already installed the above you may need to only update **npm** to the latest version:

```bash
$ sudo npm update -g npm
```

---

## Install through Github

Best way to install Pewaa API is to clone it from Github

**To clone/download the boilerplate**

```bash
$ git clone https://github.com/brianmwadime/pewaa-api.git
```

**After cloning, get into your cloned Pewaa API's directory/folder**

```bash
$ cd pewaa-api
```

**Install all of the projects dependencies with:**

```bash
$ npm install
```

__Create `app.yaml` configurations file__

The last but not the least step is to create a `app.yaml` file with your configurations in the root
directory of `pewaa-api`.

This is the same folder directory where `index.coffee` can be found.

Your `app.yaml` should look like the example below, only with your specific configuration values:

```yaml
env_variables:
  PAYBILL_NUMBER: '898998'
  PASSKEY: 'a8eac82d7ac1461ba0348b0cb24d3f8140d3afb9be864e56a10d7e8026eaed66'
  MERCHANT_ENDPOINT: 'http://merchant-endpoint.com/mpesa/payment/complete'

# Everything below is only relevant if you are looking
# to deploy Project Mulla to Google App Engine.
runtime: nodejs
vm: true

skip_files:
  - ^(.*/)?.*/node_modules/.*$
```

*__NOTE:__ The `PAYBILL_NUMBER` and `PASSKEY` are provided by Safaricom once you have registered for the MPESA G2 API.*

*__NOTE:__ The details above only serve as examples*

# Testing

## It's now ready to launch

First run the command `npm test` on your terminal and see if everything is all good. Then run:

```bash
$ npm start

Your secret session key is: 5f06b1f1-1bff-470d-8198-9ca2f18919c5
Express server listening on 8080, in development mode
```
