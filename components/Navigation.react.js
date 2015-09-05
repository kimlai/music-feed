var React = require('react');
var Link = require('react-router').Link;

module.exports = React.createClass({
    render: function () {
        return (
            <nav className="navigation">
                <ul>
                    <li><Link to="feed">Feed</Link></li>
                    <li><Link to="saved-tracks">Saved Tracks</Link></li>
                    <li><Link to="published-tracks">Published Tracks</Link></li>
                </ul>
            </nav>
        );
    }
});
