// fyi: https://qiita.com/fkooo/items/660cab0090a80861155b#%E5%AE%8C%E6%88%90%E7%94%BB%E9%9D%A2

function OnCognitoSignUp() {

    var poolData = {
        UserPoolId: 'ap-northeast-1_XXXXXXXXX', // Your user pool id here
        ClientId: 'XXXXXXXXXXXXXXXXXX', // Your client id here
    };
    var userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

    var username = document.getElementById("email").value;
    var password = document.getElementById("password").value;

    userPool.signUp(username, password, null, null, function (
        err,
        result
    ) {
        if (err) {
            alert(err.message || JSON.stringify(err));
            return;
        }
        var cognitoUser = result.user;
        console.log('user name is ' + cognitoUser.getUsername());
    });
}
