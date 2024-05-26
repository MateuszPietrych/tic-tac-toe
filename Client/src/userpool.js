import { CognitoUserPool } from 'amazon-cognito-identity-js';
const poolData = {
  UserPoolId: "us-east-1_qHxAOfA2i",
  ClientId: "cl7guj4j9ojtjptucg4cst47m",
};

export default new CognitoUserPool(poolData);