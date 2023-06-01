import React from "react"
import PropTypes from "prop-types"
class Answer extends React.Component {
  state = {
    answer: this.props.answer
  }

  render () {
    return (
      <p style={{display: this.state.answer === undefined ? 'block' : 'none' }}>
        {this.state.answer}
      </p>
    );
  }
}

Answer.propTypes = {
  answer: PropTypes.string
};
export default Answer
