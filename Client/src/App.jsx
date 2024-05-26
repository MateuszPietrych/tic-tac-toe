import React, { useState, useEffect } from "react";
import "./App.css";
import Square from "./Square/Square";
import { io } from "socket.io-client";
import LoginScreen from "./LoginPage";
import { authenticate, getNick, refreshSession, logout } from "./authenticate";

const renderFrom = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9],
];

const App = () => {
  const [gameState, setGameState] = useState(renderFrom);
  const [currentPlayer, setCurrentPlayer] = useState("circle");
  const [finishedState, setFinishetState] = useState(false);
  const [finishedArrayState, setFinishedArrayState] = useState([]);
  const [playOnline, setPlayOnline] = useState(false);
  const [loggedIn, setLoggedIn] = useState(false);
  const [socket, setSocket] = useState(null);
  const [playerName, setPlayerName] = useState("");
  const [opponentName, setOpponentName] = useState(null);
  const [playingAs, setPlayingAs] = useState(null);

  const checkWinner = () => {
    // row dynamic
    for (let row = 0; row < gameState.length; row++) {
      if (
        gameState[row][0] === gameState[row][1] &&
        gameState[row][1] === gameState[row][2]
      ) {
        setFinishedArrayState([row * 3 + 0, row * 3 + 1, row * 3 + 2]);
        return gameState[row][0];
      }
    }

    // column dynamic
    for (let col = 0; col < gameState.length; col++) {
      if (
        gameState[0][col] === gameState[1][col] &&
        gameState[1][col] === gameState[2][col]
      ) {
        setFinishedArrayState([0 * 3 + col, 1 * 3 + col, 2 * 3 + col]);
        return gameState[0][col];
      }
    }

    if (
      gameState[0][0] === gameState[1][1] &&
      gameState[1][1] === gameState[2][2]
    ) {
      return gameState[0][0];
    }

    if (
      gameState[0][2] === gameState[1][1] &&
      gameState[1][1] === gameState[2][0]
    ) {
      return gameState[0][2];
    }

    const isDrawMatch = gameState.flat().every((e) => {
      if (e === "circle" || e === "cross") return true;
    });

    if (isDrawMatch) return "draw";

    return null;
  };

  useEffect(() => {
    const winner = checkWinner();
    if (winner) {
      setFinishetState(winner);
      if(playingAs === 'circle')
        {
      if (winner === playingAs) {
        socket.emit("end_game", {
          player1: playerName,
          player2: opponentName,
          winner: playerName,
        });
  
      } else if (winner === "draw") {
        socket.emit("end_game", {
          player1: playerName,
          player2: opponentName,
          winner: "draw",
        });
      } else {
        socket.emit("end_game", {
          player1: playerName,
          player2: opponentName,
          winner: opponentName,
        });
      }
    }
  }
  }, [gameState]);

  socket?.on("opponentLeftMatch", () => {
    setFinishetState("opponentLeftMatch");
  });

  socket?.on("playerMoveFromServer", (data) => {
    const id = data.state.id;
    setGameState((prevState) => {
      let newState = [...prevState];
      const rowIndex = Math.floor(id / 3);
      const colIndex = id % 3;
      newState[rowIndex][colIndex] = data.state.sign;
      return newState;
    });
    setCurrentPlayer(data.state.sign === "circle" ? "cross" : "circle");
  });

  socket?.on("connect", function () {
    setPlayOnline(true);
  });

  socket?.on("OpponentNotFound", function () {
    setOpponentName(false);
  });

  socket?.on("OpponentFound", function (data) {
    setPlayingAs(data.playingAs);
    setOpponentName(data.opponentName);
  });

  async function playOnlineClick() {
    const username = getNick();
    setPlayerName(username);

    //console.log(process.env.GLOBAL_IP);
    const socket_io_address = "http://localhost:3000"

    refreshSession();
    const newSocket = io(socket_io_address, {
      autoConnect: true,
      extraHeaders: {
        "token": localStorage.getItem('token')
      }
    });

    newSocket?.emit("request_to_play", {
      playerName: username,
    });

    setSocket(newSocket);
  }

  const handleLogout=()=>{
    logout();
    setLoggedIn(false);
    localStorage.removeItem('token');
  };

  if (!loggedIn || localStorage.getItem('token') === null) {
    console.log("logged in: " + loggedIn);
   return (<LoginScreen setLoggedIn={setLoggedIn}/>)
  }

  if (!playOnline) {
    return (
      <div className="main-div">
        <h1 className="game-heading water-background">Tic Tac Toe</h1>
        <button onClick={playOnlineClick} className="playOnline">
          Play
        </button>
        <button
            style={{margin:"10px"}}
            variant='contained'
            onClick={handleLogout}
            className="logout"
          >
            Logout
          </button>
      </div>
    );
  }

  if (playOnline && !opponentName) {
    return (
      <div className="waiting">
        <p>Waiting for opponent</p>
        <button
            style={{margin:"10px", marginLeft:"50px"}}
            variant='contained'
            onClick={handleLogout}
            className="logout"
          >
            Logout
          </button>
      </div>
    );
  }

  return (
    <div className="main-div">
      <button
            style={{margin:"10px"}}
            variant='contained'
            onClick={handleLogout}
            className="logout"
          >
            Logout
          </button>
      <h1 className="game-heading water-background">Tic Tac Toe</h1>
      <div className="move-detection">
        <div
          className={`left ${
            currentPlayer === playingAs ? "current-move-" + currentPlayer : ""
          }`}
        >
          {playerName}
        </div>
        <div
          className={`right ${
            currentPlayer !== playingAs ? "current-move-" + currentPlayer : ""
          }`}
        >
          {opponentName}
        </div>
      </div>
      <div>
        <div className="square-wrapper">
          {gameState.map((arr, rowIndex) =>
            arr.map((e, colIndex) => {
              return (
                <Square
                  socket={socket}
                  playingAs={playingAs}
                  gameState={gameState}
                  finishedArrayState={finishedArrayState}
                  finishedState={finishedState}
                  currentPlayer={currentPlayer}
                  setCurrentPlayer={setCurrentPlayer}
                  setGameState={setGameState}
                  id={rowIndex * 3 + colIndex}
                  key={rowIndex * 3 + colIndex}
                  currentElement={e}
                />
              );
            })
          )}
        </div>
        {finishedState &&
          finishedState !== "opponentLeftMatch" &&
          finishedState !== "draw" && (
            <h3 className="finished-state">
              {finishedState === playingAs ? "You won" : "You lost"}  the
              game
            </h3>
          )}
        {finishedState &&
          finishedState !== "opponentLeftMatch" &&
          finishedState === "draw" && (
            <h3 className="finished-state">Draw</h3>
          )}
      </div>
      {!finishedState && opponentName && (
        <h2>You are playing as {playingAs}</h2>
      )}
      {finishedState && finishedState === "opponentLeftMatch" && (
        <h2>Opponent has left</h2>
      )}
    </div>
  );
};

export default App;
