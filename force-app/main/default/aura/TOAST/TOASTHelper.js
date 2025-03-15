({
    validateInputs : function(component) {
        var isValid = true;
        var errorMessages = [];

        var firstName = component.find("firstNameInput");
        var lastName = component.find("lastNameInput");
        var email = component.find("emailInput");
        var phone = component.find("phoneInput");

        [firstName, lastName, email, phone].forEach(function(input) {
            input.setCustomValidity("");
            input.reportValidity(); //  why ? ????????
        });

        // Validate first name
        if (!firstName.get("v.value")) {
            firstName.setCustomValidity("Prénom est requis");
            firstName.reportValidity();//  why ? ????????
            errorMessages.push("Prénom");
            isValid = false;
        }

        // Validate last name
        if (!lastName.get("v.value")) {
            lastName.setCustomValidity("Nom est requis");
            lastName.reportValidity();
            errorMessages.push("Nom");
            isValid = false;
        }

        // Validate email
        var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!email.get("v.value") || !emailRegex.test(email.get("v.value"))) {
            email.setCustomValidity("Veuillez entrer un email valide");
            email.reportValidity();
            errorMessages.push("Email");
            isValid = false;
        }

        // Validate phone
        var phoneRegex = /^(\+\d{1,3}[- ]?)?\d{10}$/;
        if (!phone.get("v.value") || !phoneRegex.test(phone.get("v.value"))) {
            phone.setCustomValidity("Veuillez entrer un numéro de téléphone valide");
            phone.reportValidity();
            errorMessages.push("Téléphone");
            isValid = false;
        }

        if (!isValid) {
            var errorMessage = "Veuillez renseigner:\n " + errorMessages.join("\n ");
this.showToast(component, 'Erreur de validation', errorMessage, 'error');



        }

        return isValid;
    },

    showToast : function(component, title, message, variant) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": variant,
            "duration": 5000 // 5 seconds
        });
        toastEvent.fire();
    }
})