import React, { useState } from 'react';
import LoginPage, { Username, Password, TitleSignup, TitleLogin, Submit, Title, Logo } from '@react-login-page/page8';
// import LoginLogo from 'react-login-page/logo';
import {CognitoUserAttribute } from 'amazon-cognito-identity-js';
import userpool from './userpool';
import { authenticate } from './authenticate';

const styles = { height: 690};

const LoginScreen = ({setLoggedIn}) => {

    const [email, setEmail] = useState('');
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [loginUsername, setLoginUsername] = useState('');
    const [loginPassword, setLoginPassword] = useState('');

    const handleEmailChange = (event) => {
      setEmail(event.target.value);
    };
    const handleUsernameChange = (event) => {
        setUsername(event.target.value);
    };
    const handlePasswordChange = (event) => {
        setPassword(event.target.value);
    };
    const handleConfirmPasswordChange = (event) => {
        setConfirmPassword(event.target.value);
    };

    const handleLoginUsernameChange = (event) => {
        setLoginUsername(event.target.value);
    };

    const handleLoginPasswordChange = (event) => {
        setLoginPassword(event.target.value);
    };

    const handleSignupSubmit = (e) => {
        e.preventDefault();
        if (password !== confirmPassword) {
            alert("Passwords don't match");
            return;
        }
        const attributeList = [];
        attributeList.push(
        new CognitoUserAttribute({
            Name: 'email',
            Value: email,
        }),
        );
        userpool.signUp(username, password, attributeList, null, (err, data) => {
        if (err) {
            console.log(err);
            alert("Couldn't sign up");
        } else {
            console.log(data);
            alert('User Added Successfully! You can now log in.');
        }
        });
    };

    const handleLoginSubmit = (e) => {
        e.preventDefault();
        authenticate(loginUsername,loginPassword)
          .then((data)=>{
            console.log(data);
            localStorage.setItem('token', data.accessToken.jwtToken);
            setLoggedIn(true);

          },(err)=>{
            console.log(err);
          })
          .catch(err=>console.log(err))
    };

    const css = {
        '--login-bg': '#00224D',
        '--login-btn-bg': '#00224D',
        '--login-btn-focus': 'white',
        '--login-btn-hover': '#A0153E',
        '--login-btn-active': '#A0153E',
      };

    return(
        <div style={styles}>
          <LoginPage style={css}>
            <Title />
            <TitleSignup>Sign Up</TitleSignup>
            <TitleLogin>Login</TitleLogin>
            <Logo><svg fill="#000000" height="80px" width="80px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 298.834 298.834" xml:space="preserve"><g><g><path d="M256.581,147.826c-2.885-22.698-21.553-40.538-44.624-42.136c-12.612-30.734-42.667-51.075-76.186-51.075c-43.248,0-78.817,33.506-82.109,75.923C23.788,132.214,0,157.048,0,187.333c0,31.367,25.519,56.886,56.886,56.886h193.558c26.682,0,48.39-21.707,48.39-48.39C298.834,171.223,280.378,150.85,256.581,147.826z M250.443,231.168H56.886c-24.171,0-43.836-19.664-43.836-43.835s19.665-43.836,43.836-43.836c0.798,0,1.668,0.029,2.66,0.089c3.77,0.224,6.919-2.773,6.919-6.513c0-0.063-0.001-0.125-0.003-0.188c0.045-38.178,31.12-69.221,69.308-69.221c29.502,0,55.817,18.727,65.482,46.601c0.884,2.548,3.175,4.477,6.743,4.373c16.236-0.571,32.036,11.354,35.307,28.8h-19.11c-3.604,0-6.525,2.921-6.525,6.525c0,3.604,2.921,6.525,6.525,6.525h26.249c19.486,0,35.34,15.854,35.34,35.34C285.784,215.315,269.931,231.168,250.443,231.168z"/></g></g></svg></Logo>
            <Username label="Username" placeholder="Enter username" name="userUserName" onChange={handleLoginUsernameChange}/>
            <Password label="Password" placeholder="Enter password" name="userPassword" onChange={handleLoginPasswordChange}/>
            <Submit keyname="submit" onClick={handleLoginSubmit}>Submit</Submit>
      
            <Username panel="signup" label="Email" placeholder="Enter email" keyname="e-mail" onChange={handleEmailChange}/>
            <Username panel="signup" label="Username" placeholder="Enter username" keyname="username" onChange={handleUsernameChange}/>
            <Password panel="signup" label="Password" placeholder="Enter password" keyname="password" onChange={handlePasswordChange}/>
            <Password panel="signup" label="Confirm Password" placeholder="Enter password again" keyname="confirm-password" onChange={handleConfirmPasswordChange}/>
            <Submit panel="signup" keyname="signup-submit" onClick={handleSignupSubmit}>
              Sign Up
            </Submit>
          </LoginPage>
        </div>
      );  
} 

export default LoginScreen;