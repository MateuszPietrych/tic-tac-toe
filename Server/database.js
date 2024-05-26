const mysql = require('mysql');
const db = mysql.createConnection({
    user: 'admin',
    host: 'database-1.chxvacdtr6iy.us-east-1.rds.amazonaws.com',
    database: 'gameResults',
    password: 'Mateusz2345_',
    port: 3306,
})
  

db.connect(function(err) {
if (err) throw err;
console.log("Connected!");
});

const createTableQuery = `
  CREATE TABLE IF NOT EXISTS GameResults (
    GameID INT AUTO_INCREMENT PRIMARY KEY,
    Player1 VARCHAR(50) NOT NULL,
    Player2 VARCHAR(50) NOT NULL,
    Winner VARCHAR(50) NOT NULL
  );
`;

db.query(createTableQuery, (err, results) => {
    if (err) {
      console.error('Error creating table:', err.stack);
      return;
    }
    console.log('Table created successfully');
  });

const saveGameResult = (player1, player2, winner) => {
    const insertQuery = `
      INSERT INTO GameResults (Player1, Player2, Winner)
      VALUES (?, ?, ?)
    `;
    const values = [player1, player2, winner];
  
    db.query(insertQuery, values, (err, results) => {
      if (err) {
        console.error('Error saving game result:', err.stack);
        return;
      }
      console.log('Game result saved successfully');
    });
  };

module.exports = {
    saveGameResult
}