// For example in app/javascripts/components/hello.js
import React from 'react'
import { hot } from 'react-hot-loader'

// hello variable
const Hello = () => <div>Hello World!</div>

// This is the important line!
export default hot(module)(Hello)
