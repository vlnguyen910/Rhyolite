import '../models/course_concept.dart';
import '../models/curriculum_catalog.dart';

abstract class IConceptRelationService {
  List<CourseConcept> getAllConcepts();
  List<String> getConceptsForCourse(
    String courseCode, {
    List<String>? dynamicConcepts,
  });
  List<CourseRelation> getRelatedCourses(
    String courseCode,
    List<CurriculumCourse> allCourses, {
    List<String>? dynamicConcepts,
    double minRelevance = 0.05,
  });
  List<CourseRelation> getCurriculumConceptRelations(
    List<CurriculumCourse> courses, {
    double minRelevance = 0.15,
  });
  List<String> getCoursesForConcept(
    String conceptName,
    List<CurriculumCourse> allCourses,
  );
  CourseConcept? findConcept(String conceptName);
}

class ConceptRelationService implements IConceptRelationService {
  ConceptRelationService();

  // Danh mục Concept chuẩn hóa hệ thống cho FPTU SE
  static const Map<String, CourseConcept> _knownConcepts = {
    'Backend': CourseConcept(
      id: 'backend',
      name: 'Backend',
      description: 'Phát triển dịch vụ máy chủ, API, kiến trúc server-side và cơ sở dữ liệu.',
      category: 'Chuyên ngành',
      colorHex: '#38bdf8',
    ),
    'Frontend': CourseConcept(
      id: 'frontend',
      name: 'Frontend',
      description: 'Xây dựng giao diện web tương tác, SPA với React và công nghệ hiện đại.',
      category: 'Chuyên ngành',
      colorHex: '#ec4899',
    ),
    'Web Development': CourseConcept(
      id: 'web-dev',
      name: 'Web Development',
      description: 'Quy trình và công nghệ xây dựng ứng dụng web toàn diện.',
      category: 'Chuyên ngành',
      colorHex: '#06b6d4',
    ),
    'Toán': CourseConcept(
      id: 'math',
      name: 'Toán',
      description: 'Khối kiến thức toán học đại cương, giải tích, đại số, rời rạc và xác suất thống kê.',
      category: 'Toán học',
      colorHex: '#f59e0b',
    ),
    'Cơ sở lập trình': CourseConcept(
      id: 'prog-fund',
      name: 'Cơ sở lập trình',
      description: 'Nền tảng tư duy thuật toán, cấu trúc dữ liệu cơ bản và lập trình hàm.',
      category: 'Nền tảng',
      colorHex: '#10b981',
    ),
    'Lập trình hướng đối tượng': CourseConcept(
      id: 'oop',
      name: 'Lập trình hướng đối tượng',
      description: 'Mô hình OOP, đóng gói, kế thừa, đa hình và thiết kế phần mềm hướng đối tượng.',
      category: 'Nền tảng',
      colorHex: '#6366f1',
    ),
    'Cấu trúc dữ liệu & Giải thuật': CourseConcept(
      id: 'dsa',
      name: 'Cấu trúc dữ liệu & Giải thuật',
      description: 'Cấu trúc dữ liệu tuyến tính, cây, đồ thị và các giải thuật tối ưu hóa.',
      category: 'Nền tảng',
      colorHex: '#8b5cf6',
    ),
    'Cơ sở dữ liệu': CourseConcept(
      id: 'database',
      name: 'Cơ sở dữ liệu',
      description: 'Thiết kế mô hình dữ liệu quan hệ, SQL, tối ưu hóa truy vấn và NoSQL.',
      category: 'Hệ thống dữ liệu',
      colorHex: '#14b8a6',
    ),
    'Kỹ thuật phần mềm': CourseConcept(
      id: 'se',
      name: 'Kỹ thuật phần mềm',
      description: 'Quy trình phát triển phần mềm, quản lý yêu cầu, kiểm thử và thiết kế kiến trúc.',
      category: 'Chuyên ngành',
      colorHex: '#f97316',
    ),
    'Trí tuệ nhân tạo': CourseConcept(
      id: 'ai',
      name: 'Trí tuệ nhân tạo',
      description:
          'Học máy, học sâu, xử lý dữ liệu thông minh và thị giác máy tính.',
      category: 'Công nghệ tiên tiến',
      colorHex: '#a855f7',
    ),
    'Khoa học dữ liệu': CourseConcept(
      id: 'data-science',
      name: 'Khoa học dữ liệu',
      description: 'Thu thập, xử lý, trực quan hóa và khai phá dữ liệu lớn.',
      category: 'Công nghệ tiên tiến',
      colorHex: '#0ea5e9',
    ),
    'Hệ thống máy tính': CourseConcept(
      id: 'computer-systems',
      name: 'Hệ thống máy tính',
      description: 'Kiến trúc máy tính, hệ điều hành, vi điều khiển và mạng truyền thông.',
      category: 'Hệ thống',
      colorHex: '#64748b',
    ),
    'Mạng máy tính': CourseConcept(
      id: 'networking',
      name: 'Mạng máy tính',
      description: 'Mô hình OSI/TCP-IP, định tuyến, giao thức truyền thông và hạ tầng mạng.',
      category: 'Hệ thống',
      colorHex: '#0284c7',
    ),
    'An toàn thông tin': CourseConcept(
      id: 'infosec',
      name: 'An toàn thông tin',
      description: 'Nguyên lý bảo mật hệ thống, mã hóa và an ninh mạng.',
      category: 'Hệ thống',
      colorHex: '#ef4444',
    ),
    'Internet of Things': CourseConcept(
      id: 'iot',
      name: 'Internet of Things',
      description: 'Hệ thống IoT, cảm biến, vi xử lý và kết nối vạn vật.',
      category: 'Hệ thống',
      colorHex: '#d97706',
    ),
    'Lập trình di động': CourseConcept(
      id: 'mobile',
      name: 'Lập trình di động',
      description: 'Phát triển ứng dụng Android, iOS và đa nền tảng.',
      category: 'Chuyên ngành',
      colorHex: '#84cc16',
    ),
    'Phát triển Game': CourseConcept(
      id: 'game-dev',
      name: 'Phát triển Game',
      description:
          'Thiết kế mechanics game, engine đồ họa và lập trình game 2D/3D.',
      category: 'Chuyên ngành',
      colorHex: '#e11d48',
    ),
    'UI/UX': CourseConcept(
      id: 'ui-ux',
      name: 'UI/UX',
      description: 'Thiết kế giao diện người dùng, nghiên cứu hành vi và tối ưu hóa trải nghiệm.',
      category: 'Chuyên ngành',
      colorHex: '#f43f5e',
    ),
    'Kỹ năng mềm': CourseConcept(
      id: 'soft-skills',
      name: 'Kỹ năng mềm',
      description: 'Giao tiếp, làm việc nhóm, kỹ năng học tập, thuyết trình và đạo đức nghề nghiệp.',
      category: 'Kỹ năng',
      colorHex: '#eab308',
    ),
    'Khởi nghiệp': CourseConcept(
      id: 'entrepreneurship',
      name: 'Khởi nghiệp',
      description: 'Trải nghiệm khởi nghiệp, tư duy kinh doanh và dự án khởi nghiệp tốt nghiệp.',
      category: 'Kỹ năng',
      colorHex: '#f59e0b',
    ),
    'Ngoại ngữ': CourseConcept(
      id: 'languages',
      name: 'Ngoại ngữ',
      description: 'Tiếng Anh, tiếng Nhật sơ/trung cấp và tiếng Hàn trong môi trường công nghệ.',
      category: 'Ngoại ngữ',
      colorHex: '#3b82f6',
    ),
    'Giáo dục thể chất': CourseConcept(
      id: 'physical-ed',
      name: 'Giáo dục thể chất',
      description:
          'Võ thuật Vovinam và cờ vua rèn luyện thể lực và tư duy chiến thuật.',
      category: 'Thể chất',
      colorHex: '#22c55e',
    ),
    'Nhạc cụ truyền thống': CourseConcept(
      id: 'traditional-music',
      name: 'Nhạc cụ truyền thống',
      description: 'Nghệ thuật và biểu diễn nhạc cụ dân tộc Việt Nam.',
      category: 'Văn hóa nghệ thuật',
      colorHex: '#a855f7',
    ),
    'Chính trị - Pháp luật': CourseConcept(
      id: 'political-science',
      name: 'Chính trị - Pháp luật',
      description:
          'Triết học Mác - Lênin, Tư tưởng Hồ Chí Minh và Lịch sử Đảng.',
      category: 'Khoa học xã hội',
      colorHex: '#dc2626',
    ),
  };

  // Mapping định sẵn cho TOÀN BỘ 89 môn học trong dataset FPTU SE
  static const Map<String, List<String>> _courseConceptCatalog = {
    // 1. Math / Toán
    'MAE101': ['Toán'],
    'MAD101': ['Toán'],
    'MAS291': ['Toán'],

    // 2. Programming Fundamentals & OOP / Nền tảng lập trình
    'PRF192': ['Cơ sở lập trình'],
    'PRO192': ['Lập trình hướng đối tượng', 'Cơ sở lập trình'],
    'PRO192c': ['Lập trình hướng đối tượng', 'Cơ sở lập trình'],
    'LAB211': ['Lập trình hướng đối tượng', 'Cơ sở lập trình'],
    'CSD201': ['Cấu trúc dữ liệu & Giải thuật', 'Cơ sở lập trình'],
    'PRP201c': ['Cơ sở lập trình'],
    'PRN212': ['Lập trình hướng đối tượng'],
    'PRN222': ['Lập trình hướng đối tượng', 'Backend'],

    // 3. Backend & Web Development
    'SDN302': ['Backend', 'Web Development', 'Cơ sở dữ liệu'],
    'PRJ301': ['Backend', 'Web Development', 'Cơ sở dữ liệu'],
    'HSF302': ['Backend', 'Web Development'],
    'SBA301': ['Backend', 'Frontend', 'Web Development'],
    'PRN232': ['Backend', 'Web Development', 'Cơ sở dữ liệu'],

    // 4. Frontend & UI/UX
    'WED201c': ['Frontend', 'Web Development'],
    'FER202': ['Frontend', 'Web Development'],
    'WDU203c': ['UI/UX', 'Frontend'],
    'WDP301': ['Web Development', 'Kỹ thuật phần mềm'],

    // 5. Database & Data Science & AI
    'DBI202': ['Cơ sở dữ liệu'],
    'DBI202-OLD': ['Cơ sở dữ liệu'],
    'DBM301': ['Khoa học dữ liệu', 'Cơ sở dữ liệu'],
    'DHV301': ['Khoa học dữ liệu'],
    'PDS301m': ['Khoa học dữ liệu'],
    'MDS301': ['Trí tuệ nhân tạo', 'Khoa học dữ liệu'],
    'AIL304m': ['Trí tuệ nhân tạo', 'Toán'],
    'DPL303m': ['Trí tuệ nhân tạo'],

    // 6. Computer Systems & Architecture & Networking
    'CSI106': ['Hệ thống máy tính'],
    'CEA201': ['Hệ thống máy tính'],
    'OSG202': ['Hệ thống máy tính'],
    'NWC204': ['Mạng máy tính', 'Hệ thống máy tính'],
    'IOT102': ['Internet of Things', 'Hệ thống máy tính'],
    'IoT102t': ['Internet of Things', 'Hệ thống máy tính'],
    'MIP201': ['Internet of Things', 'Hệ thống máy tính'],
    'DCD301': ['Hệ thống máy tính'],
    'ECI101': ['Hệ thống máy tính'],
    'IAO201c': ['An toàn thông tin', 'Mạng máy tính'],

    // 7. Software Engineering & Project Management
    'SWE201c': ['Kỹ thuật phần mềm'],
    'SWE202c': ['Kỹ thuật phần mềm'],
    'SWR302': ['Kỹ thuật phần mềm'],
    'SWD392': ['Kỹ thuật phần mềm'],
    'SWT301': ['Kỹ thuật phần mềm'],
    'SWP391': ['Kỹ thuật phần mềm'],
    'SEP490': ['Kỹ thuật phần mềm'],
    'SET490': ['Kỹ thuật phần mềm'],
    'PIT490': ['Kỹ thuật phần mềm'],
    'GRC490': ['Kỹ thuật phần mềm'],
    'PMG201c': ['Kỹ thuật phần mềm', 'Kỹ năng mềm'],
    'OJT202': ['Kỹ thuật phần mềm'],

    // 8. Mobile & Game Development
    'PRM393': ['Lập trình di động'],
    'MMA301': ['Lập trình di động'],
    'FGU301': ['Phát triển Game'],
    'AGU301': ['Phát triển Game'],
    'GDC301': ['Phát triển Game', 'UI/UX'],
    'PRU213': ['Phát triển Game'],

    // 9. Soft Skills, Entrepreneurship, Academic
    'SSL101c': ['Kỹ năng mềm'],
    'SSA101': ['Kỹ năng mềm'],
    'SSG104': ['Kỹ năng mềm'],
    'SSG105': ['Kỹ năng mềm'],
    'ENW493c': ['Kỹ năng mềm'],
    'ITE302c': ['Kỹ năng mềm'],
    'EXE101': ['Khởi nghiệp', 'Kỹ năng mềm'],
    'EXE201': ['Khởi nghiệp', 'Kỹ năng mềm'],
    'EXE402': ['Khởi nghiệp'],
    'OTP101': ['Kỹ năng mềm'],

    // 10. Foreign Languages
    'PEN': ['Ngoại ngữ'],
    'JPD113': ['Ngoại ngữ'],
    'JPD123': ['Ngoại ngữ'],
    'JPD133': ['Ngoại ngữ'],
    'JPD316': ['Ngoại ngữ'],
    'JIS401': ['Ngoại ngữ'],
    'JIT401': ['Ngoại ngữ'],
    'KOR311': ['Ngoại ngữ'],

    // 11. Political Sciences & Law
    'MLN111': ['Chính trị - Pháp luật'],
    'MLN122': ['Chính trị - Pháp luật'],
    'MLN131': ['Chính trị - Pháp luật'],
    'HCM202': ['Chính trị - Pháp luật'],
    'VNR202': ['Chính trị - Pháp luật'],

    // 12. Physical Education
    'VOV114': ['Giáo dục thể chất'],
    'VOV124': ['Giáo dục thể chất'],
    'VOV134': ['Giáo dục thể chất'],
    'COV111': ['Giáo dục thể chất'],
    'COV121': ['Giáo dục thể chất'],
    'COV131': ['Giáo dục thể chất'],

    // 13. Traditional Musical Instruments
    'DBA103': ['Nhạc cụ truyền thống'],
    'DNG103': ['Nhạc cụ truyền thống'],
    'DNH103': ['Nhạc cụ truyền thống'],
    'DSA103': ['Nhạc cụ truyền thống'],
    'DTB103': ['Nhạc cụ truyền thống'],
    'DTR103': ['Nhạc cụ truyền thống'],
    'TRG103': ['Nhạc cụ truyền thống'],
  };

  // Các cặp môn có quan hệ nền tảng / tiền đề kiến thức tự nhiên
  static const Map<String, List<String>> _foundationDownstreams = {
    'PRF192': [
      'PRO192',
      'PRO192c',
      'LAB211',
      'CSD201',
      'PRJ301',
      'PRN212',
      'SDN302',
      'PRP201c',
      'PRM393',
      'FGU301',
    ],
    'PRO192': ['CSD201', 'LAB211', 'PRJ301', 'HSF302', 'SBA301'],
    'PRO192c': ['CSD201', 'LAB211', 'PRJ301', 'HSF302'],
    'DBI202': ['PRJ301', 'SDN302', 'HSF302', 'PRN232', 'DBM301'],
    'DBI202-OLD': ['PRJ301', 'SDN302', 'HSF302', 'PRN232'],
    'MAE101': ['MAS291', 'MAD101', 'AIL304m', 'MDS301'],
    'MAD101': ['CSD201', 'AIL304m'],
    'WED201c': ['FER202', 'WDP301', 'SDN302', 'PRJ301'],
    'FER202': ['SDN302', 'SBA301', 'WDP301'],
    'SWE201c': ['SWR302', 'SWD392', 'SWT301', 'SWP391', 'SEP490'],
  };

  @override
  List<CourseConcept> getAllConcepts() => _knownConcepts.values.toList();

  @override
  CourseConcept? findConcept(String conceptName) {
    final normalized = conceptName.trim().toLowerCase();
    for (final entry in _knownConcepts.entries) {
      if (entry.key.toLowerCase() == normalized ||
          entry.value.id.toLowerCase() == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  List<String> getConceptsForCourse(
    String courseCode, {
    List<String>? dynamicConcepts,
  }) {
    final set = <String>{};
    final standard = _courseConceptCatalog[courseCode.toUpperCase()];
    if (standard != null) set.addAll(standard);
    if (dynamicConcepts != null) {
      for (final concept in dynamicConcepts) {
        final trimmed = concept.trim();
        if (trimmed.isNotEmpty) set.add(trimmed);
      }
    }
    return set.toList();
  }

  @override
  List<CourseRelation> getRelatedCourses(
    String courseCode,
    List<CurriculumCourse> allCourses, {
    List<String>? dynamicConcepts,
    double minRelevance = 0.05,
  }) {
    final code = courseCode.toUpperCase();
    final sourceCourse = allCourses.cast<CurriculumCourse?>().firstWhere(
      (c) => c?.code.toUpperCase() == code,
      orElse: () => null,
    );

    final sourceConcepts = getConceptsForCourse(
      code,
      dynamicConcepts: dynamicConcepts,
    );
    final results = <CourseRelation>[];

    for (final other in allCourses) {
      final otherCode = other.code.toUpperCase();
      if (otherCode == code) continue;

      final otherConcepts = getConceptsForCourse(otherCode);
      final shared = sourceConcepts
          .toSet()
          .intersection(otherConcepts.toSet())
          .toList();

      var score = 0.0;
      var relationType = CourseRelationType.sharedConcept;
      final reasons = <String>[];

      // 1. Điểm từ Concept chung
      if (shared.isNotEmpty) {
        final jaccard =
            shared.length /
            (sourceConcepts.length + otherConcepts.length - shared.length);
        score += (shared.length * 0.22 + jaccard * 0.28).clamp(0.0, 0.60);
        reasons.add('Chung ${shared.join(', ')}');
      }

      // 2. Điểm từ quan hệ Tiên quyết
      final isDirectPrereq =
          sourceCourse?.prerequisiteCodes.contains(otherCode) ?? false;
      final isDependent = other.prerequisiteCodes.contains(code);
      if (isDirectPrereq || isDependent) {
        score += 0.25;
        relationType = CourseRelationType.prerequisite;
        reasons.add(
          isDirectPrereq ? 'Môn tiên quyết của $code' : 'Môn học sau cần $code',
        );
      }

      // 3. Quan hệ Nền tảng (Foundation)
      final downstreams = _foundationDownstreams[code] ?? const [];
      final upstream = _foundationDownstreams[otherCode] ?? const [];
      if (downstreams.contains(otherCode)) {
        score += 0.18;
        relationType = CourseRelationType.foundation;
        reasons.add('$code là tiền đề kiến thức cho $otherCode');
      } else if (upstream.contains(code)) {
        score += 0.18;
        relationType = CourseRelationType.foundation;
        reasons.add('$otherCode là tiền đề kiến thức cho $code');
      }

      // 4. Nhóm học phần hoặc chuyên ngành liền kề
      if (sourceCourse != null) {
        final sharedGroups = sourceCourse.groupCodes.toSet().intersection(
          other.groupCodes.toSet(),
        );
        if (sharedGroups.isNotEmpty &&
            !sourceCourse.groupCodes.contains(code)) {
          score += 0.10;
          reasons.add('Cùng nhóm lựa chọn');
        }
      }

      final finalScore = score.clamp(0.0, 1.0);
      if (finalScore >= minRelevance) {
        results.add(
          CourseRelation(
            sourceCourseCode: code,
            targetCourseCode: otherCode,
            relationType: relationType,
            relevanceScore: finalScore,
            sharedConcepts: shared,
            explanation: reasons.join(' · '),
          ),
        );
      }
    }

    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return results;
  }

  @override
  List<CourseRelation> getCurriculumConceptRelations(
    List<CurriculumCourse> courses, {
    double minRelevance = 0.15,
  }) {
    final seenPairs = <String>{};
    final relations = <CourseRelation>[];

    for (var i = 0; i < courses.length; i++) {
      final a = courses[i];
      final rels = getRelatedCourses(
        a.code,
        courses,
        minRelevance: minRelevance,
      );
      for (final rel in rels) {
        final key = a.code.compareTo(rel.targetCourseCode) < 0
            ? '${a.code}:${rel.targetCourseCode}'
            : '${rel.targetCourseCode}:${a.code}';
        if (seenPairs.add(key)) {
          relations.add(rel);
        }
      }
    }

    return relations;
  }

  @override
  List<String> getCoursesForConcept(
    String conceptName,
    List<CurriculumCourse> allCourses,
  ) {
    final target = conceptName.trim().toLowerCase();
    final matches = <String>[];
    for (final course in allCourses) {
      final concepts = getConceptsForCourse(course.code);
      if (concepts.any((c) => c.toLowerCase() == target)) {
        matches.add(course.code);
      }
    }
    return matches;
  }
}
