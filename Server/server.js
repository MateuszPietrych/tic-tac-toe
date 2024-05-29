const { createServer } = require("http");
const { Server } = require("socket.io");
const {saveGameResult} = require("./database.js");

const httpServer = createServer();

const io = new Server(httpServer, {
  cors: "http://localhost:5173/",
});

const allUsers = {};
const allRooms = [];

isValid = false;

const jsonwebtoken = require('jsonwebtoken');
const jwkToPem = require('jwk-to-pem');
const jsonWebKeys = [
  {
    "alg": "RS256",
      "e": "AQAB",
      "kid": "nraBqPvVWb4kNVIkrPCNq4Hl7peRgXwKdhyj87Dc3NQ=",
      "kty": "RSA",
      "n": "3PvhTMfamyvYmt8t-u76QoLLwjWrY2KbG7E8GHXlbsrZnMkmGFjSZDicpVhpAtHO3uAagC3X4tmbZ_HBqmEkWkKyligzjddCffMOT1ikrJ74LK5Vddx-jl0yAGGtFezIKIhC0rUTAkOe_NJkfj9OtYQ3jKBaM229OTw5pqkl6Br_tUsCfliCKVYhenU31cXqkUxgOuwRzTrFEACHRyDuXtHK8-QKMArU0aEzDxha9JQQU_69J1URIq9fhkU0jlH2WER6RLBG-fHxmpSStwM6OMREEr9YRbouWIVCXBSthlDqepOVODGnFyPGks4alInM4V-qorwMMi2auZOVqQfcyw",
      "use": "sig"
  },
  {
    "alg": "RS256",
    "e": "AQAB",
    "kid": "MwAkoV46P7TH/ZOVN5L5VOSYUId61l4R6gTuu0P/t/M=",
    "kty": "RSA",
    "n": "qBYC9NgXesvjEccHPYKqgSCsdgEGEMotkh8WLJkPnRrqeS70NxNC3byh9WXNSZaW0ZS98lau5umwzCQ83yal3RNmJI_wAQhgRZzFv-eLv29wS8FRVFIcl1HGrfKM6T123BUni8h-1xpXN-J6WPgA_OAhvs8a45dV4HMswklqv4I8uHZRRB8YzGM8pe7CQo0ptDyV_j4hjdTR7DZIw13pnoP-bZVArBW7vx9rC2XjDm9eK6u9zJMIqTZZFPwyjBXM5E-epkF0ut-NPjhruUanEKdq-KgqmLATRmaEZA9bZrhFB7Tod6brkBfge1_YyrkePy_HhEVMAnNPbIhrq7K2cQ",
    "use": "sig"
  }
]

function decodeTokenHeader(token) {
  const [headerEncoded] = token.split('.');
  const buff = new Buffer(headerEncoded, 'base64');
  const text = buff.toString('ascii');
  return JSON.parse(text);
}

function getJsonWebKeyWithKID(kid) {
  for (let jwk of jsonWebKeys) {
      if (jwk.kid === kid) {
          return jwk;
      }
  }
  return null
}

function verifyJsonWebTokenSignature(token, jsonWebKey, clbk) {
  const pem = jwkToPem(jsonWebKey);
  jsonwebtoken.verify(token, pem, {algorithms: ['RS256']}, (err, decodedToken) => clbk(err, decodedToken))
}

function validateToken(token) {
  const header = decodeTokenHeader(token);  // {"kid":"XYZAAAAAAAAAAAAAAA/1A2B3CZ5x6y7MA56Cy+6abc=", "alg": "RS256"}
  const jsonWebKey = getJsonWebKeyWithKID(header.kid);
  verifyJsonWebTokenSignature(token, jsonWebKey, (err, decodedToken) => {
      if (err) {
          console.log(err);
      } else {
          console.log(decodedToken);
          isValid = true;
      }
  })
}


io.on("connection", (socket) => {
  allUsers[socket.id] = {
    socket: socket,
    playing: false,
    online: true,
  };

  isValid = false;
  const headers = socket.handshake.headers;

  // Access the token from the headers
  const token = headers.token;

  validateToken(token)

  if (!isValid) {
    socket.disconnect();
    return;
  }

  //console.log("Token:", token);


  socket.on("request_to_play", (data) => {
    const currentUser = allUsers[socket.id];
    currentUser.playerName = data.playerName;

    let opponentPlayer;

    for (const key in allUsers) {
      const user = allUsers[key];
      if (user.online && !user.playing && socket.id !== key) {
        opponentPlayer = user;
        break;
      }
    }

    if (opponentPlayer) {

      opponentPlayer.playing =  true;
      currentUser.playing = true;      


      allRooms.push({
        player1: opponentPlayer,
        player2: currentUser,
      });

      currentUser.socket.emit("OpponentFound", {
        opponentName: opponentPlayer.playerName,
        playingAs: "circle",
      });

      opponentPlayer.socket.emit("OpponentFound", {
        opponentName: currentUser.playerName,
        playingAs: "cross",
      });

      currentUser.socket.on("playerMoveFromClient", (data) => {
        opponentPlayer.socket.emit("playerMoveFromServer", {
          ...data,
        });
      });

      opponentPlayer.socket.on("playerMoveFromClient", (data) => {
        currentUser.socket.emit("playerMoveFromServer", {
          ...data,
        });
      });
    } else {
      currentUser.socket.emit("OpponentNotFound");
    }
  });

  socket.on("disconnect", function () {
    const currentUser = allUsers[socket.id];
    currentUser.online = false;
    currentUser.playing = false;

    for (let index = 0; index < allRooms.length; index++) {
      const { player1, player2 } = allRooms[index];

      if (player1.socket.id === socket.id) {
        player2.socket.emit("opponentLeftMatch");
        break;
      }

      if (player2.socket.id === socket.id) {
        player1.socket.emit("opponentLeftMatch");
        break;
      }
    }
  });

  socket.on("end_game", (data) => {
    console.log(data);
  
    saveGameResult(data.player1, data.player2, data.winner);
  });

});

httpServer.listen(3000);
