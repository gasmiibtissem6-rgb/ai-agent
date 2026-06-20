// services/api/generate-token.js
const jwt = require('jsonwebtoken');

// Your exact legacy secret from your screenshot
const secret = 'Owtu4FJDWQWVwEyJsc70Mep9nzdAK9aCy4fGudGNV/QPY10QDsFuezCsFBmanxEexKibNR6W1WwsFvYsihAx+w==';

const payload = {
  sub: "99f4ea05-a0b9-458c-a4c3-c9ca07871f6c", // Ensure this UUID exists in your profiles table!
  email: "zoussema1@gmail.com",
  role: "authenticated"
};

// Sign the token using HS256 algorithm natively
const token = jwt.sign(payload, secret, { algorithm: 'HS256' });

console.log("\n🚀 YOUR PERFECT TEST TOKEN:\n");
console.log("Bearer " + token);
console.log("\nCopy the entire line above directly into ReqBin!");