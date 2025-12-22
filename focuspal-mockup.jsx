import React, { useState, useEffect } from 'react';
import { Camera, Clock, BarChart3, Settings, Home, Award, Heart, Zap, Book, Gamepad2, Users, Moon, Play, Pause, RotateCcw, ChevronRight, Star, TrendingUp } from 'lucide-react';

const FocusPalMockup = () => {
  const [currentScreen, setCurrentScreen] = useState('home');
  const [timerRunning, setTimerRunning] = useState(false);
  const [timerSeconds, setTimerSeconds] = useState(1500); // 25 minutes
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [currentChild, setCurrentChild] = useState('Alex');

  // Timer logic
  useEffect(() => {
    let interval;
    if (timerRunning && timerSeconds > 0) {
      interval = setInterval(() => {
        setTimerSeconds(prev => prev - 1);
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [timerRunning, timerSeconds]);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const percentage = ((1500 - timerSeconds) / 1500) * 100;

  const categories = [
    { id: 'homework', name: 'Homework', icon: Book, color: '#FF6B6B', time: 45 },
    { id: 'play', name: 'Creative Play', icon: Star, color: '#4ECDC4', time: 60 },
    { id: 'physical', name: 'Physical', icon: Zap, color: '#FFD93D', time: 30 },
    { id: 'screen', name: 'Screen Time', icon: Gamepad2, color: '#A78BFA', time: 90 },
    { id: 'reading', name: 'Reading', icon: Book, color: '#F472B6', time: 20 },
    { id: 'social', name: 'Social', icon: Users, color: '#34D399', time: 40 },
  ];

  const weekData = [
    { day: 'Mon', homework: 60, play: 45, screen: 80 },
    { day: 'Tue', homework: 45, play: 60, screen: 70 },
    { day: 'Wed', homework: 75, play: 30, screen: 90 },
    { day: 'Thu', homework: 50, play: 55, screen: 75 },
    { day: 'Fri', homework: 40, play: 70, screen: 100 },
    { day: 'Sat', homework: 20, play: 90, screen: 85 },
    { day: 'Sun', homework: 15, play: 80, screen: 95 },
  ];

  const achievements = [
    { id: 1, name: '7-Day Streak!', icon: '🔥', earned: true },
    { id: 2, name: 'Homework Hero', icon: '📚', earned: true },
    { id: 3, name: 'Balanced Week', icon: '⚖️', earned: false },
    { id: 4, name: 'Early Bird', icon: '🌅', earned: true },
  ];

  // Screen Components
  const HomeScreen = () => (
    <div className="flex-1 overflow-y-auto pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 px-6 pt-12 pb-8 rounded-b-3xl shadow-lg">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-3xl font-black text-white mb-1" style={{ fontFamily: "'Fredoka', sans-serif" }}>
              Hey {currentChild}! 👋
            </h1>
            <p className="text-purple-100 text-sm">Ready to crush your goals?</p>
          </div>
          <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-lg">
            <span className="text-3xl">🦊</span>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-3 text-center">
            <div className="text-2xl font-bold text-white">5</div>
            <div className="text-xs text-purple-100">Day Streak</div>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-3 text-center">
            <div className="text-2xl font-bold text-white">180</div>
            <div className="text-xs text-purple-100">Points Today</div>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-3 text-center">
            <div className="text-2xl font-bold text-white">12</div>
            <div className="text-xs text-purple-100">Badges</div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="px-6 py-6">
        <h2 className="text-xl font-bold text-gray-800 mb-4" style={{ fontFamily: "'Fredoka', sans-serif" }}>
          Quick Start
        </h2>
        <div className="grid grid-cols-2 gap-4 mb-6">
          <button
            onClick={() => setCurrentScreen('timer')}
            className="bg-gradient-to-br from-orange-400 to-red-500 rounded-3xl p-6 text-left shadow-lg transform hover:scale-105 transition-transform"
          >
            <Clock className="text-white mb-2" size={32} />
            <div className="text-white font-bold text-lg">Start Timer</div>
            <div className="text-orange-100 text-sm">Focus time!</div>
          </button>
          <button
            onClick={() => setCurrentScreen('log')}
            className="bg-gradient-to-br from-blue-400 to-cyan-500 rounded-3xl p-6 text-left shadow-lg transform hover:scale-105 transition-transform"
          >
            <Zap className="text-white mb-2" size={32} />
            <div className="text-white font-bold text-lg">Log Activity</div>
            <div className="text-blue-100 text-sm">Track your time</div>
          </button>
        </div>

        {/* Today's Activities */}
        <h2 className="text-xl font-bold text-gray-800 mb-4" style={{ fontFamily: "'Fredoka', sans-serif" }}>
          Today's Activities
        </h2>
        <div className="space-y-3">
          {categories.slice(0, 4).map((cat) => {
            const Icon = cat.icon;
            return (
              <div key={cat.id} className="bg-white rounded-2xl p-4 shadow-md flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-xl flex items-center justify-center" style={{ backgroundColor: cat.color + '20' }}>
                    <Icon size={24} style={{ color: cat.color }} />
                  </div>
                  <div>
                    <div className="font-bold text-gray-800">{cat.name}</div>
                    <div className="text-sm text-gray-500">{cat.time} minutes today</div>
                  </div>
                </div>
                <ChevronRight className="text-gray-400" />
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );

  const TimerScreen = () => (
    <div className="flex-1 overflow-y-auto pb-24">
      {/* Header */}
      <div className="px-6 pt-12 pb-6">
        <button onClick={() => setCurrentScreen('home')} className="text-gray-600 mb-4">
          ← Back
        </button>
        <h1 className="text-3xl font-black text-gray-800" style={{ fontFamily: "'Fredoka', sans-serif" }}>
          Focus Timer
        </h1>
      </div>

      {/* Visual Timer */}
      <div className="px-6 py-8">
        <div className="relative w-full max-w-sm mx-auto">
          {/* Circular Timer */}
          <svg className="w-full h-auto" viewBox="0 0 200 200">
            {/* Background circle */}
            <circle
              cx="100"
              cy="100"
              r="85"
              fill="none"
              stroke="#f0f0f0"
              strokeWidth="12"
            />
            {/* Progress circle */}
            <circle
              cx="100"
              cy="100"
              r="85"
              fill="none"
              stroke="url(#gradient)"
              strokeWidth="12"
              strokeLinecap="round"
              strokeDasharray={`${percentage * 5.34} 534`}
              transform="rotate(-90 100 100)"
              style={{ transition: 'stroke-dasharray 0.3s ease' }}
            />
            <defs>
              <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: '#FF6B6B', stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: '#FFD93D', stopOpacity: 1 }} />
              </linearGradient>
            </defs>
          </svg>
          
          {/* Time Display */}
          <div className="absolute inset-0 flex items-center justify-center flex-col">
            <div className="text-6xl font-black text-gray-800" style={{ fontFamily: "'Fredoka', sans-serif" }}>
              {formatTime(timerSeconds)}
            </div>
            <div className="text-gray-500 mt-2">Focus Time</div>
          </div>
        </div>

        {/* Controls */}
        <div className="flex gap-4 justify-center mt-12">
          <button
            onClick={() => setTimerRunning(!timerRunning)}
            className="w-20 h-20 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center shadow-lg transform hover:scale-110 transition-transform"
          >
            {timerRunning ? <Pause className="text-white" size={32} /> : <Play className="text-white ml-1" size={32} />}
          </button>
          <button
            onClick={() => { setTimerSeconds(1500); setTimerRunning(false); }}
            className="w-20 h-20 bg-gradient-to-br from-gray-400 to-gray-500 rounded-full flex items-center justify-center shadow-lg transform hover:scale-110 transition-transform"
          >
            <RotateCcw className="text-white" size={28} />
          </button>
        </div>

        {/* Category Selection */}
        <div className="mt-12">
          <h3 className="text-lg font-bold text-gray-800 mb-4">What are you working on?</h3>
          <div className="grid grid-cols-3 gap-3">
            {categories.slice(0, 6).map((cat) => {
              const Icon = cat.icon;
              return (
                <button
                  key={cat.id}
                  onClick={() => setSelectedCategory(cat.id)}
                  className={`p-4 rounded-2xl transition-all ${
                    selectedCategory === cat.id
                      ? 'ring-4 ring-offset-2 shadow-lg scale-105'
                      : 'bg-white shadow-md hover:shadow-lg'
                  }`}
                  style={{
                    backgroundColor: selectedCategory === cat.id ? cat.color + '20' : 'white',
                    ringColor: selectedCategory === cat.id ? cat.color : 'transparent'
                  }}
                >
                  <Icon size={24} style={{ color: cat.color }} className="mx-auto mb-2" />
                  <div className="text-xs font-semibold text-gray-700 text-center">{cat.name}</div>
                </button>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );

  const StatsScreen = () => (
    <div className="flex-1 overflow-y-auto pb-24">
      {/* Header */}
      <div className="bg-gradient-to-br from-cyan-400 to-blue-500 px-6 pt-12 pb-8 rounded-b-3xl shadow-lg">
        <h1 className="text-3xl font-black text-white mb-2" style={{ fontFamily: "'Fredoka', sans-serif" }}>
          Your Progress
        </h1>
        <p className="text-cyan-100">This week's awesome stats! 📊</p>
      </div>

      <div className="px-6 py-6">
        {/* Weekly Chart */}
        <div className="bg-white rounded-3xl p-6 shadow-lg mb-6">
          <h3 className="text-lg font-bold text-gray-800 mb-4">This Week</h3>
          <div className="flex items-end justify-between gap-2 h-48">
            {weekData.map((day, idx) => (
              <div key={idx} className="flex-1 flex flex-col items-center gap-2">
                <div className="w-full flex flex-col gap-1 justify-end flex-1">
                  <div
                    className="w-full rounded-t-lg bg-gradient-to-t from-purple-400 to-purple-500"
                    style={{ height: `${(day.screen / 100) * 100}%` }}
                  />
                  <div
                    className="w-full rounded-t-lg bg-gradient-to-t from-green-400 to-green-500"
                    style={{ height: `${(day.play / 100) * 100}%` }}
                  />
                  <div
                    className="w-full rounded-t-lg bg-gradient-to-t from-red-400 to-red-500"
                    style={{ height: `${(day.homework / 100) * 100}%` }}
                  />
                </div>
                <div className="text-xs font-semibold text-gray-600">{day.day}</div>
              </div>
            ))}
          </div>
          <div className="flex gap-4 justify-center mt-6 flex-wrap">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-red-500" />
              <span className="text-xs text-gray-600">Homework</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-green-500" />
              <span className="text-xs text-gray-600">Play</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-purple-500" />
              <span className="text-xs text-gray-600">Screen</span>
            </div>
          </div>
        </div>

        {/* Achievements */}
        <div className="bg-white rounded-3xl p-6 shadow-lg mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-gray-800">Achievements</h3>
            <Award className="text-yellow-500" size={24} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            {achievements.map((achievement) => (
              <div
                key={achievement.id}
                className={`p-4 rounded-2xl text-center ${
                  achievement.earned
                    ? 'bg-gradient-to-br from-yellow-100 to-yellow-200 border-2 border-yellow-400'
                    : 'bg-gray-100 opacity-50'
                }`}
              >
                <div className="text-3xl mb-2">{achievement.icon}</div>
                <div className="text-sm font-bold text-gray-800">{achievement.name}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Balance Meter */}
        <div className="bg-white rounded-3xl p-6 shadow-lg">
          <h3 className="text-lg font-bold text-gray-800 mb-4">Activity Balance</h3>
          <div className="space-y-4">
            {categories.map((cat) => {
              const Icon = cat.icon;
              const progress = (cat.time / 120) * 100;
              return (
                <div key={cat.id}>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <Icon size={16} style={{ color: cat.color }} />
                      <span className="text-sm font-semibold text-gray-700">{cat.name}</span>
                    </div>
                    <span className="text-sm text-gray-500">{cat.time}m</span>
                  </div>
                  <div className="w-full h-3 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: `${progress}%`,
                        backgroundColor: cat.color
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );

  const LogActivityScreen = () => (
    <div className="flex-1 overflow-y-auto pb-24">
      {/* Header */}
      <div className="px-6 pt-12 pb-6">
        <button onClick={() => setCurrentScreen('home')} className="text-gray-600 mb-4">
          ← Back
        </button>
        <h1 className="text-3xl font-black text-gray-800 mb-2" style={{ fontFamily: "'Fredoka', sans-serif" }}>
          Log Activity
        </h1>
        <p className="text-gray-500">What did you just do?</p>
      </div>

      <div className="px-6 py-6">
        <div className="grid grid-cols-2 gap-4">
          {categories.map((cat) => {
            const Icon = cat.icon;
            return (
              <button
                key={cat.id}
                className="bg-white rounded-3xl p-6 shadow-lg hover:shadow-xl transform hover:scale-105 transition-all"
                style={{ borderLeft: `6px solid ${cat.color}` }}
              >
                <Icon size={40} style={{ color: cat.color }} className="mb-3" />
                <div className="text-lg font-bold text-gray-800 text-left">{cat.name}</div>
                <div className="text-sm text-gray-500 text-left mt-1">Tap to log</div>
              </button>
            );
          })}
        </div>

        <div className="mt-8 bg-gradient-to-br from-purple-100 to-pink-100 rounded-3xl p-6">
          <div className="flex items-start gap-4">
            <div className="text-3xl">💡</div>
            <div>
              <h4 className="font-bold text-purple-900 mb-1">Quick Tip!</h4>
              <p className="text-sm text-purple-700">
                Logging your activities helps you see patterns and build better habits. Keep it up!
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  // Bottom Navigation
  const BottomNav = () => (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-4 flex justify-around items-center shadow-lg">
      <button
        onClick={() => setCurrentScreen('home')}
        className={`flex flex-col items-center gap-1 ${currentScreen === 'home' ? 'text-purple-600' : 'text-gray-400'}`}
      >
        <Home size={24} />
        <span className="text-xs font-semibold">Home</span>
      </button>
      <button
        onClick={() => setCurrentScreen('timer')}
        className={`flex flex-col items-center gap-1 ${currentScreen === 'timer' ? 'text-purple-600' : 'text-gray-400'}`}
      >
        <Clock size={24} />
        <span className="text-xs font-semibold">Timer</span>
      </button>
      <button
        onClick={() => setCurrentScreen('log')}
        className={`flex flex-col items-center gap-1 ${currentScreen === 'log' ? 'text-purple-600' : 'text-gray-400'}`}
      >
        <Zap size={24} />
        <span className="text-xs font-semibold">Log</span>
      </button>
      <button
        onClick={() => setCurrentScreen('stats')}
        className={`flex flex-col items-center gap-1 ${currentScreen === 'stats' ? 'text-purple-600' : 'text-gray-400'}`}
      >
        <BarChart3 size={24} />
        <span className="text-xs font-semibold">Stats</span>
      </button>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      <link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;600;700&display=swap" rel="stylesheet" />
      
      {/* Phone Frame */}
      <div className="max-w-md mx-auto bg-white min-h-screen shadow-2xl relative flex flex-col">
        {/* Status Bar */}
        <div className="bg-gray-900 text-white px-6 py-2 flex justify-between items-center text-xs">
          <span>9:41</span>
          <div className="flex gap-1 items-center">
            <div className="w-4 h-3 border border-white rounded-sm" />
            <div className="w-1 h-3 bg-white rounded-sm" />
          </div>
        </div>

        {/* Screen Content */}
        {currentScreen === 'home' && <HomeScreen />}
        {currentScreen === 'timer' && <TimerScreen />}
        {currentScreen === 'stats' && <StatsScreen />}
        {currentScreen === 'log' && <LogActivityScreen />}

        {/* Bottom Navigation */}
        <BottomNav />
      </div>

      {/* Screen Selector (for demo purposes) */}
      <div className="max-w-md mx-auto mt-8 p-4 bg-white rounded-lg shadow-md">
        <p className="text-sm text-gray-600 text-center mb-3">
          🎨 Interactive Mockup - Click the navigation buttons to explore different screens
        </p>
        <div className="flex gap-2 justify-center flex-wrap">
          <button
            onClick={() => setCurrentScreen('home')}
            className="px-4 py-2 bg-purple-100 text-purple-700 rounded-lg text-sm font-semibold hover:bg-purple-200"
          >
            Home Screen
          </button>
          <button
            onClick={() => setCurrentScreen('timer')}
            className="px-4 py-2 bg-orange-100 text-orange-700 rounded-lg text-sm font-semibold hover:bg-orange-200"
          >
            Visual Timer
          </button>
          <button
            onClick={() => setCurrentScreen('stats')}
            className="px-4 py-2 bg-blue-100 text-blue-700 rounded-lg text-sm font-semibold hover:bg-blue-200"
          >
            Progress Stats
          </button>
          <button
            onClick={() => setCurrentScreen('log')}
            className="px-4 py-2 bg-green-100 text-green-700 rounded-lg text-sm font-semibold hover:bg-green-200"
          >
            Log Activity
          </button>
        </div>
      </div>
    </div>
  );
};

export default FocusPalMockup;