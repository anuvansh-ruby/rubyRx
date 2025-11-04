class TutorialItem {
  final String imagePath;
  final String title;
  final String description;

  const TutorialItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class TutorialData {
  static const List<TutorialItem> tutorialItems = [
    TutorialItem(
      imagePath: 'lib/assets/tutorial_1.png',
      title: 'Welcome to Ruby AI',
      description:
          'Discover the power of AI-driven solutions that help you work smarter, not harder. Get ready to transform your workflow.',
    ),
    TutorialItem(
      imagePath: 'lib/assets/tutorial_2.png',
      title: 'Smart Automation',
      description:
          'Experience intelligent automation that learns from your patterns and streamlines your daily tasks with precision.',
    ),
    TutorialItem(
      imagePath: 'lib/assets/tutorial_3.png',
      title: 'Powered by Innovation',
      description:
          'Built with cutting-edge technology to provide you with the most reliable and efficient AI companion for your journey.',
    ),
  ];
}
