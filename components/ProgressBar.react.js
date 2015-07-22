var React = require('react');

module.exports = React.createClass({
    render: function () {
        return (
            <div className="progress-bar">{this.props.progress}%</div>
        );
    }
});
