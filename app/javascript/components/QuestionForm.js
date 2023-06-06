import React, { useRef, useState } from "react"
import PropTypes from "prop-types"
import Answer from "./Answer"

// magic number - perhaps just a short delay for suspense or
// something, or to let the audio start playing.
const ANSWER_SHOWER_DELAY = 1200

function QuestionForm(props) {
  const [question, setQuestion] = useState(props.question);
  const [answer, setAnswer] = useState(props.answer);
  const [asking, setAsking] = useState(false);
  const [answerShower, setAnswerShower] = useState(NaN);
  const questionTextareaRef = useRef(null);

  function handleSubmit(e) {
    e.preventDefault();

    setAsking(true)

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
      setAnswerShower(
        setTimeout(() => {
          showAnswer(response.answer, 0)
        }, ANSWER_SHOWER_DELAY)
      )
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

      setAnswerShower(
        setTimeout(() => {
          showAnswer(text, index + 1)
        }, interval)
      )
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

  function reset() {
    clearTimeout(answerShower)

    questionTextareaRef.current.focus()

    setAsking(false)
    setAnswer(null)
    setAnswerShower(NaN)
  }

  return (
    <React.Fragment>
      <form method="post" onSubmit={handleSubmit}>
        <label>
          // is there a way to focus this element and put the cursor in it when the answer isn't set?'
          Ask a question: <textarea name="question" id="question" value={question} onChange={handleQuestionChange} ref={questionTextareaRef}></textarea>
        </label>

        <div className="buttons">
          <button type="submit" id="ask-button" style={{display: answer === null ? 'block' : 'none' }} disabled={ asking === true ? "disabled" : "" }>
            { !asking ? "Ask question" : "Asking..." }
          </button>
        </div>
      </form>

      <Answer answer={answer} reset={reset}/>
    </React.Fragment>
  );
}

QuestionForm.propTypes = {
  question: PropTypes.string,
  answer: PropTypes.string,
  asking: PropTypes.bool,
  answerShower: PropTypes.number,
};
export default QuestionForm
