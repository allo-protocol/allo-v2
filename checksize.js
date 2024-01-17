const fs = require('fs');
const path = require('path');

// Path to the compiled contract JSON file
const filePath = path.join(
  __dirname,
  'out/GameManagerStrategy.sol/GameManagerStrategy.json'
);

console.log('filePath', filePath);

// Read the JSON file
const json = JSON.parse(fs.readFileSync(filePath, 'utf8'));

console.log('json', typeof json);

// Get the bytecode length (excluding the '0x' prefix)
const bytecodeLength = json.bytecode.object.length - 2; // remove 2 characters for '0x'

console.log('json.bytecode', json.bytecode);
console.log('bytecodeLength', bytecodeLength);

// Calculate the size in bytes (each byte is represented by two hex characters)
const sizeInBytes = bytecodeLength / 2;

console.log(`Contract size: ${sizeInBytes} bytes`);
