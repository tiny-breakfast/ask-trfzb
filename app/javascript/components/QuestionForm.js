import React, { useState } from "react"
import PropTypes from "prop-types"
import Answer from "./Answer"

function QuestionForm(props) {
  const [question, setQuestion] = useState(props.question);
  const [answer, setAnswer] = useState(props.answer);

  function handleSubmit(e) {
    e.preventDefault();

    // Read the form data
    const form = e.target;
    const formData = new FormData(form);

    fetch("/questions", {
      method: form.method,
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
    }).then((data) => {
      if (data.ok) {
        const result = data.json();
        return result
      }
      throw new Error("some kind of error, wish I knew");
    }).then((response) => {
      showAnswer(response.answer, 0)
    })
  }

  function showAnswer(text, index) {
    if (index < text.length + 1) {

      var interval = randomInteger(30, 70);
      setAnswer(
        // this is probably not performant.
        //
        // not sure how to get a concatenative solution to work,
        // though.
        text.slice(0, index)
      )
      // is settimeout idiomatic in react?
      setTimeout(function () { showAnswer(text, index + 1); }, interval);
    } else {
      // todo: 
      // history.pushState({}, null, "/question/" + window.newQuestionId);
      // $("#ask-another-button").css("display", "block");
    }
  }

  function randomInteger(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }

  function handleQuestionChange(event) {
    setQuestion(event.target.value);
  }

  return (
    <React.Fragment>
      <form method="post" onSubmit={handleSubmit}>
        <label>
          Ask a question: <textarea name="question" id="question" value={question} onChange={handleQuestionChange}></textarea>
        </label>

        <div className="buttons">
          <button type="submit" id="ask-button" style={{display: answer === undefined ? 'block' : 'none' }}>
            Ask question
          </button>
        </div>
      </form>

      <Answer answer={answer} setAnswer={setAnswer}/>
    </React.Fragment>
  );
}

QuestionForm.propTypes = {
  question: PropTypes.string,
  answer: PropTypes.string,
};
export default QuestionForm
