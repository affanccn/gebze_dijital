class EBelediyeCategory {
  final int id;
  final String name;
  final String icon;
  final List<EBelediyeService> services;

  const EBelediyeCategory({
    required this.id,
    required this.name,
    this.icon = '',
    required this.services,
  });

  factory EBelediyeCategory.fromMap(Map<String, dynamic> map) {
    return EBelediyeCategory(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
      services:
          (map['services'] as List<dynamic>?)
              ?.map((s) => EBelediyeService.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'services': services.map((s) => s.toMap()).toList(),
    };
  }
}

class EBelediyeService {
  final int id;
  final String name;
  final String description;
  final String url;
  final bool hasModal;
  final bool isNew;
  final List<EBelediyeModalStep> modalSteps;

  const EBelediyeService({
    required this.id,
    required this.name,
    this.description = '',
    required this.url,
    this.hasModal = false,
    this.isNew = false,
    this.modalSteps = const [],
  });

  factory EBelediyeService.fromMap(Map<String, dynamic> map) {
    return EBelediyeService(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      url: map['url'] as String? ?? '',
      hasModal: map['hasModal'] as bool? ?? false,
      isNew: map['isNew'] as bool? ?? false,
      modalSteps:
          (map['modalSteps'] as List<dynamic>?)
              ?.map(
                (ms) => EBelediyeModalStep.fromMap(ms as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'hasModal': hasModal,
      'isNew': isNew,
      'modalSteps': modalSteps.map((m) => m.toMap()).toList(),
    };
  }
}

class EBelediyeModalStep {
  final String id;
  final String title;
  final String backStep;
  final List<EBelediyeModalOption> options;

  const EBelediyeModalStep({
    required this.id,
    required this.title,
    this.backStep = '',
    required this.options,
  });

  factory EBelediyeModalStep.fromMap(Map<String, dynamic> map) {
    return EBelediyeModalStep(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      backStep: map['backStep'] as String? ?? '',
      options:
          (map['options'] as List<dynamic>?)
              ?.map(
                (o) => EBelediyeModalOption.fromMap(o as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'backStep': backStep,
      'options': options.map((o) => o.toMap()).toList(),
    };
  }
}

class EBelediyeModalOption {
  final String text;
  final String url;
  final String tooltip;
  final String nextStep;

  const EBelediyeModalOption({
    required this.text,
    this.url = '',
    this.tooltip = '',
    this.nextStep = '',
  });

  factory EBelediyeModalOption.fromMap(Map<String, dynamic> map) {
    return EBelediyeModalOption(
      text: map['text'] as String? ?? '',
      url: map['url'] as String? ?? '',
      tooltip: map['tooltip'] as String? ?? '',
      nextStep: map['nextStep'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'url': url, 'tooltip': tooltip, 'nextStep': nextStep};
  }
}
