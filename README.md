MDContactForm
=============

Dynamic iOS Contact Form. This Drop-in ViewController can be used to simulate an online web form.
Currently the following field types are supported:
    kMDContactFormTextField         Single line text input
    kMDContactFormTextView          Multi-line text input
    kMDContactFormHidden            Hidden field



Quick set-up:
1. Upload a script to handle a standard POST form. If you already have a contact form on your website, you can probably just use the same page. (At least to get started.)
2. Change the URL in MDContactForm.plist to point to the location that your form submits to.
3. Alter the plist as described below to POST the proper values to your server.



What can you do?
- I'd love to hear from you if you plan to use this in a project or if you have any feature requests.
- Spread the word! Let your friends know if you think this is useful!
- Really love it? You are welcomed to donate to the cause here: http://mikecheck.net/index.php (Please be sure you let us know what you like and what you'd like to see developed further.)



The format of MDContactForm.plist is as follows:

KEY                         MEANING
//Global
MDContactForm_Title                     Sets the viewcontroll title and the title of the navigationItem
MDContactForm_Message                   Text that is displayed above the form. Ex. "Fill out the form below, we'd appreciate it!"

//Submit
MDContactForm_SubmitTitle               Title of the Submit button
MDContactForm_SubmitURL                 URL to POST the values to
MDContactForm_SubmitSuccessMessage      Message on 200 response from server
MDContactForm_SubmitFailed              Message on any other response code from the server

//Form Items
MDContactForm_Items                     Array of dictionary form items
MDContactForm_InputType                 Type of input, see MDFormInputTypes typedef for values
MDContactForm_InputIdentifier           Name of POST variable
MDContactForm_InputValue                Default input value
MDContactForm_InputRequired             Bool value, form can only be submitted if required fields are filled in with some value
MDContactForm_InputDisplayName          Text displayed above form input to describe the field
MDContactForm_InputFontSize             Font size for field

//Only supported on MDTextView Form Item
MDContactForm_InputHeight               Height of field

//Only supported on MDTextField Form Item
MDContactForm_InputTextPlaceholder      Placeholder text


Additional useful constants are located at the top of MDContactFormViewController.m
