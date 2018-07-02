const path = require('path')

module.exports = {
  entry: path.join(__dirname, 'src/js', 'index.js'), // Our frontend will be inside the src folder
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'build.js' // The final file will be created in dist/build.js
  },
  module: {
    rules: [{
       test: /\.scss$/, // To load the scss in react
       use: [{
            loader: "style-loader"
          }, {
            loader: "css-loader" 
          }, {
            loader: "sass-loader"
          }],
       include: /src/
    }, {
       test: /\.jsx?$/, // To load the js and jsx files
       loader: 'babel-loader',
       exclude: /node_modules/,
       query: {
          presets: ['react']
       }
    }]
  }
}