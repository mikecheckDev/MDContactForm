<?php
    if (isset($_POST['email']) && 
        isset($_POST['name']) && 
        isset($_POST['email']) && 
        isset($_POST['comments']) && 
        isset($_POST['problemLocation'])) {

        $to = "support@mikecheck.net";
        $subject = "***** MikeCheck Issue Report";
        $email = $_POST['email'] ;
        $message =  "Problem with: ".$_POST['problemLocation'].
                    "\nName: ".$_POST['name'].
                    "\nPhone: ".$_POST['phone'].
                    "\nEmail: ".$_POST['email'].
                    "\nComments: ###\n".$_POST['comments'].
                    "\n###";
        $headers = "From: $email";
        
        if (mail ($to, $subject, $message)) {

            http_response_code(200);
        } else {

            http_response_code(400);
        }
    }
?>