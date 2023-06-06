import React, { useState } from "react"
import PropTypes from "prop-types"
function Answer(props) {
  return (
    <p id="answer-container" style={{display: props.answer === undefined ? 'none' : 'block' }}>
      <strong>Answer:</strong> <span id="answer">{props.answer}</span>
    </p>
  );
}

Answer.propTypes = {
  answer: PropTypes.string
};
export default Answer
