// @flow

export type CardParameters = {
  number: string,
  cvv: string,
  expirationDate: string,
  cardholderName: string,
  amount: string
  firstName: string,
  lastName: string,
  company: string,
  countryName: string,
  countryCodeAlpha2: string,
  countryCodeAlpha3: string,
  countryCodeNumeric: string,
  locality: string,
  postalCode: string,
  region: string,
  streetAddress: string,
  extendedAddress: string,
  token: string
};

export type IOSCardParameters = {
  number: string,
  cvv: string,
  expirationMonth: string,
  expirationYear: string,
  expirationDate: string,
  cardholderName: string,
  token: string
  amount: string
  billingAddress: {
    postalCode: string,
    streetAddress: string,
    extendedAddress: string,
    locality: string,
    region: string,
    countryName: string,
    countryCodeAlpha2: string,
    countryCodeAlpha3: string,
    countryCodeNumeric: string,
    firstName: string,
    lastName: string,
    company: string,
  },
};

export type AndroidCardParameters = CardParameters;