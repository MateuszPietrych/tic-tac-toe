import { AuthenticationDetails, CognitoUser, CognitoRefreshToken } from 'amazon-cognito-identity-js';
import userpool from './userpool';
export const authenticate=(Username,Password)=>{
    return new Promise((resolve,reject)=>{
        const user=new CognitoUser({
            Username:Username,
            Pool:userpool
        });

        const authDetails= new AuthenticationDetails({
            Username:Username,
            Password
        });

        user.authenticateUser(authDetails,{
            onSuccess:(result)=>{
                console.log("login successful");
                resolve(result);
            },
            onFailure:(err)=>{
                console.log("login failed",err);
                reject(err);
            }
        });
    });
};

export const logout = () => {
    userpool.getCurrentUser().signOut();
    window.location.href = '/';
};

export const getNick = () => {
    return userpool.getCurrentUser().getUsername();
}

export const refreshSession = () => {
    var cognitoUser = userpool.getCurrentUser();
    
    var refreshToken = new CognitoRefreshToken({ RefreshToken: localStorage.getItem('refresh')})
  
    cognitoUser.getSession(function(err, session) {
      localStorage.setItem('token', session.accessToken.jwtToken);
        if (err) {                
          console.log(err);
        }
        else {
          if (!session.isValid()) {
            /* Session Refresh */
            cognitoUser.refreshSession(refreshToken, (err, session) => {
              if (err) { 
                  console.log('In the err' + err);
              }
              else {
                  localStorage.setItem('token', session.accessToken.jwtToken);
              }
            });   
          }
        }
      });
}