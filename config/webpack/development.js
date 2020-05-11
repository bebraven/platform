process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const webpackerReactconfigureHotModuleReplacement = require('webpacker-react/configure-hot-module-replacement')

const config = environment.toWebpackConfig()

module.exports = webpackerReactconfigureHotModuleReplacement(config);
module.exports.cache = true;
