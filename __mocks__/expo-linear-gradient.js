const React = require("react");
// Mock without requiring react-native to avoid __fbBatchedBridgeConfig errors
function LinearGradient(props){ return React.createElement("div", props, props && props.children); }
module.exports = { __esModule: true, default: LinearGradient, LinearGradient };
