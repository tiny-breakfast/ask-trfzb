import React, { useState } from "react"
import PropTypes from "prop-types"
function Answer(props) {
  return (
    <React.Fragment>
      <p id="answer-container" style={{display: props.answer === null ? 'none' : 'block' }}>
        <strong>Answer:</strong> <span id="answer">{props.answer}</span>
      </p>
      <div className="buttons" style={{display: props.answer === null ? 'none' : 'block' }}>
        <button id="ask-another-button" onClick={props.reset} style={{display: props.answering ? 'none' : 'block' }}>Ask another question</button>
      </div>
    </React.Fragment>
  );
}

Answer.propTypes = {
  answer: PropTypes.string
};
export default Answer
