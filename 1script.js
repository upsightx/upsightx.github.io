document.addEventListener('DOMContentLoaded', function () {
    const dateElement = document.getElementById('date');
    const weekendElement = document.getElementById('weekend');
    const duanwuElement = document.getElementById('duanwu');
    const zhongqiuElement = document.getElementById('zhongqiu');
    const guoqingElement = document.getElementById('guoqing');
    const yuandanElement = document.getElementById('yuandan');
    const chuxiElement = document.getElementById('chuxi');
    const fishKnowledgeElement = document.getElementById('fish-knowledge');
    const fishTipsElement = document.getElementById('fish-tips');
    const fishJokeElement = document.getElementById('fish-joke');
    const yiListElement = document.getElementById('yi-list');
    const jiListElement = document.getElementById('ji-list');
    const workoutCountdownTitleElement = document.getElementById('workout-countdown-title');
    const workoutCountdownElement = document.getElementById('workout-countdown');

    const holidays = {
        '端午': new Date('2024-06-10'),
        '中秋': new Date('2024-09-17'),
        '国庆': new Date('2024-10-01'),
        '元旦': new Date('2025-01-01'),
        '除夕': new Date('2025-01-29')
    };

    const fishKnowledges = [
        "适当摸鱼有助于提高工作效率。",
        "摸鱼可以帮助缓解压力，改善心情。",
        "通过摸鱼可以激发创造力和灵感。",
        "适当休息有助于保持身心健康。",
        "摸鱼可以让你更好地集中注意力。",
        "摸鱼时，可以发现新的兴趣爱好。",
        "摸鱼可以让你更好地平衡工作和生活。",
        "短暂的摸鱼可以提高你的幸福感。",
        "适当的摸鱼可以预防职业倦怠。",
        "摸鱼有助于增进同事之间的关系。",
        "摸鱼时，你可以进行自我反思和总结。",
        "摸鱼可以让你有时间思考和规划未来。",
        "摸鱼可以帮助你保持创造性的思维。",
        "适当的摸鱼可以减少工作中的压力。",
        "摸鱼可以让你更好地享受工作。",
        "摸鱼时，你可以学习新的技能。",
        "摸鱼可以帮助你更好地适应工作节奏。",
        "适当的摸鱼可以提高你的工作满意度。",
        "摸鱼时，你可以放松身心，充电再出发。",
        "摸鱼可以让你有时间关注自己的健康。"
    ];

    const fishTips = [
        "找一个隐蔽的角落，悄悄休息。",
        "在上厕所时，稍微多待一会儿。",
        "利用午休时间打个盹。",
        "与同事聊天，放松一下。",
        "适当浏览新闻网站，了解时事。",
        "在工位上听音乐，放松心情。",
        "走出办公室，呼吸新鲜空气。",
        "假装思考，实际上在放空。",
        "做些与工作无关的读物阅读。",
        "偶尔看看搞笑视频，放松心情。",
        "用喝水的借口，多走动一下。",
        "整理桌面，顺便摸鱼。",
        "调整座椅，享受片刻宁静。",
        "写写画画，放飞思绪。",
        "利用会议间隙，休息一下。",
        "给朋友发信息，聊聊天。",
        "假装打电话，放松一下。",
        "看看窗外，放松眼睛。",
        "进行简短的冥想，缓解压力。",
        "用便签写下灵感，实际在摸鱼。"
    ];

    const yiActivities = [
        "吃瓜追剧",
        "聊天灌水",
        "睡觉摸鱼",
        "玩游戏",
        "看书",
        "散步",
        "听音乐",
        "打盹",
        "逛街",
        "做白日梦",
        "冥想",
        "喝咖啡",
        "发呆",
        "看电影",
        "画画",
        "种花",
        "钓鱼",
        "摄影",
        "烹饪",
        "练瑜伽"
    ];

    const jiActivities = [
        "加班",
        "拼命工作",
        "学习新技能",
        "开会",
        "写报告",
        "整理文件",
        "数据分析",
        "市场调研",
        "客户拜访",
        "计划制定",
        "目标设定",
        "团队建设",
        "提升业绩",
        "项目管理",
        "时间管理",
        "绩效考核",
        "竞争分析",
        "战略规划",
        "企业培训",
        "工作总结"
    ];

    function updateDate() {
        const now = new Date();
        const options = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' };
        const dateString = now.toLocaleDateString('zh-CN', options);
        dateElement.textContent = dateString;

        const dayOfWeek = now.getDay();
        const daysUntilWeekend = (6 - dayOfWeek + 7) % 7;
        weekendElement.textContent = daysUntilWeekend;

        duanwuElement.textContent = getDaysUntil(holidays['端午']);
        zhongqiuElement.textContent = getDaysUntil(holidays['中秋']);
        guoqingElement.textContent = getDaysUntil(holidays['国庆']);
        yuandanElement.textContent = getDaysUntil(holidays['元旦']);
        chuxiElement.textContent = getDaysUntil(holidays['除夕']);

        updateFishKnowledge();
        updateFishTips();
        updateFishJoke();
        updateYiJi();
        updateWorkoutCountdown();
    }

    function getDaysUntil(holiday) {
        const now = new Date();
        const timeDiff = holiday - now;
        const daysDiff = Math.ceil(timeDiff / (1000 * 3600 * 24));
        return daysDiff;
    }

    function updateFishKnowledge() {
        const randomIndex = Math.floor(Math.random() * fishKnowledges.length);
        fishKnowledgeElement.textContent = fishKnowledges[randomIndex];
    }

    function updateFishTips() {
        const randomIndex = Math.floor(Math.random() * fishTips.length);
        fishTipsElement.textContent = fishTips[randomIndex];
    }

    function updateFishJoke() {
        fetch('https://api.vvhan.com/api/text/joke')
            .then(response => response.text())
            .then(joke => {
                fishJokeElement.textContent = joke;
            })
            .catch(error => {
                fishJokeElement.textContent = '获取笑话失败，请稍后再试。';
                console.error('Error fetching joke:', error);
            });
    }

    function updateYiJi() {
        const randomYi = getRandomItems(yiActivities, 3);
        const randomJi = getRandomItems(jiActivities, 3);

        yiListElement.innerHTML = randomYi.map(item => `<div>${item}</div>`).join('');
        jiListElement.innerHTML = randomJi.map(item => `<div>${item}</div>`).join('');
    }

    function getRandomItems(arr, num) {
        const shuffled = arr.sort(() => 0.5 - Math.random());
        return shuffled.slice(0, num);
    }

    function updateWorkoutCountdown() {
        const now = new Date();
        const dayOfWeek = now.getDay();
        const hours = now.getHours();

        if (dayOfWeek === 0 || dayOfWeek === 6 || hours < 9 || hours >= 18) {
            workoutCountdownTitleElement.style.display = 'none';
            workoutCountdownElement.style.display = 'none';
            return;
        }

        workoutCountdownTitleElement.style.display = 'block';
        workoutCountdownElement.style.display = 'block';

        const workoutTime = new Date();
        workoutTime.setHours(18, 0, 0, 0);

        const timeDiff = workoutTime - now;
        const remainingHours = Math.floor((timeDiff / (1000 * 60 * 60)) % 24);
        const remainingMinutes = Math.floor((timeDiff / (1000 * 60)) % 60);
        const remainingSeconds = Math.floor((timeDiff / 1000) % 60);

        workoutCountdownElement.textContent = `还有 ${remainingHours} 小时 ${remainingMinutes} 分钟 ${remainingSeconds} 秒 下班`;
    }

    setInterval(updateWorkoutCountdown, 1000);
    updateDate();
});
