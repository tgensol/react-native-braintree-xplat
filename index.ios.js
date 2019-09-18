// @flow

'use strict';

import {
  NativeModules,
} from 'react-native';

import type {
  CardParameters
} from './types';

const RCTBraintree = NativeModules.Braintree;

var Braintree = {
  setupWithURLScheme(serverUrl, urlscheme) {
    return new Promise(function (resolve, reject) {
      RCTBraintree.setupWithURLScheme(serverUrl, urlscheme, function (success) {
        success == true ? resolve(true) : reject('Invalid Token');
      });
    });
  },

  setup(token) {
    return new Promise(function (resolve, reject) {
      RCTBraintree.setup(token, function (success) {
        success == true ? resolve(true) : reject('Invalid Token');
      });
    });
  },

  showPayPalViewController(amount: string) {
    return new Promise(function (resolve, reject) {
      RCTBraintree.showPayPalViewController(amount, function (err, nonce) {
        nonce != null ? resolve(nonce) : reject(err);
      });
    });
  },
  check3DSecure(parameters: CardParameters = {}) {
    return new Promise(function (resolve, reject) {
      RCTBraintree.check3DSecure(parameters, function (
        err,
        nonce
      ) {
        nonce !== null ?
          resolve(nonce) :
          reject(err);
      });
    });
  },
  getCardNonce(parameters: CardParameters = {}) {
    return new Promise(function (resolve, reject) {
      RCTBraintree.getCardNonce(parameters, function (
        err,
        nonce
      ) {
        nonce !== null ?
          resolve(nonce) :
          reject(err);
      });
    });
  },

  getDeviceData(options = {}) {
    return new Promise(function (resolve, reject) {
      RCTBraintree.getDeviceData(options, function (err, deviceData) {
        deviceData != null ? resolve(deviceData) : reject(err);
      });
    });
  },
};

module.exports = Braintree;