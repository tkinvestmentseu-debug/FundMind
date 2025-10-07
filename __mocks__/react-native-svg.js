const React = require("react");
function Svg(props){
  return React.createElement("svg", props, props && props.children);
}
const proxy = new Proxy({}, { get: () => Svg });
module.exports = proxy;
module.exports.__esModule = true;
module.exports.default = Svg;
