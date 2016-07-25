function highlight (msg, usernames) {
  return msg.split(/@([a-z]+)/).map((fragment, idx) => {
    if (idx % 2 === 0) {
      return fragment
    } else {
      if (usernames.indexOf(fragment) > -1) {
        return {span: fragment}
      } else {
        return fragment
      }
    }
  })
}


usernames = ["rstacruz", "vic"]
var output = highlight("Hello @rstacruz whats up is @vic there", usernames)
console.log(output)
