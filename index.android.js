'use strict';

import {
  NativeModules
} from 'react-native';
import {
  mapParameters
} from './utils';

const Braintree = NativeModules.Braintree;

module.exports = {
  setup(token) {
    return new Promise(function (resolve, reject) {
      Braintree.setup(token, test => resolve(test), err => reject(err));
    });
  },

  getCardNonce(parameters = {}) {
    return new Promise(function (resolve, reject) {
      Braintree.getCardNonce(
        mapParameters(parameters),
        nonce => resolve(nonce),
        err => reject(err)
      );
    });
  },
  check3DSecure(parameters = {}) {
    return new Promise(function (resolve, reject) {
      Braintree.check3DSecure(mapParameters(parameters), nonce => resolve(nonce),
        err => reject(err));
    });
  },
  showPayPalViewController(amount) {
    return new Promise(function (resolve, reject) {
      Braintree.paypalRequest(amount, nonce => resolve(nonce), error => reject(error));
    });
  },
};