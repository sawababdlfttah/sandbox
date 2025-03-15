public class MyCustomObjectC {
    private ApexPages.StandardController standardController;

    public MyCustomObjectC(ApexPages.StandardController controller) {
        this.standardController = controller;
    }

    public PageReference save() {
        // Add custom logic if needed
        return standardController.save();
    }
}