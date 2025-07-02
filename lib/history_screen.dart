import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wufcare/main.dart';

class HistoryScreen extends StatefulWidget {
  final String lastId;
  final Map<String, dynamic> profileData;

  const HistoryScreen({super.key, required this.lastId, required this.profileData});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> dates = [];

  @override
  void initState() {
    super.initState();
    fetchDates();
  }

  Future<void> fetchDates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vitals_record')
        .doc(widget.lastId)
        .collection('dates')
        .get();

    final allDates = snapshot.docs.map((doc) => doc.id).toList();

    setState(() {
      dates = allDates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MyHomePage(
                  title: 'AniHealth',
                  collarId: widget.lastId,
                  profileData: widget.profileData,
                ),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: dates.isEmpty
            ? const Center(child: Text('No history found.'))
            : ListView.builder(
          itemCount: dates.length,
          itemBuilder: (context, index) {
            return ListTile(
              tileColor: Colors.white,
              title: Text(
                dates[index],
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.black),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DateDetailsScreen(
                      date: dates[index],
                      collarId: widget.lastId,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class DateDetailsScreen extends StatelessWidget {
  final String date;
  final String collarId;

  const DateDetailsScreen({super.key, required this.date, required this.collarId});

  Future<Map<String, dynamic>?> fetchHealthData() async {
    final doc = await FirebaseFirestore.instance
        .collection('vitals_record')
        .doc(collarId)
        .collection('dates')
        .doc(date)
        .get();

    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Details for $date')),
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchHealthData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available for this date.'));
          }

          final data = snapshot.data!;
          final heartRates = (data['heartRate'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? [];
          final spo2 = (data['spo2'] as List?)?.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList() ?? [];
          final bodyTemp = (data['bodyTemp'] as List?)?.map((e) => e is double ? e : double.tryParse(e.toString()) ?? 0.0).toList() ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Heart Rate', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                HeartRateGraph(data: heartRates),
                const SizedBox(height: 24),

                Text('SpO₂', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SpO2Graph(data: spo2),
                const SizedBox(height: 24),

                Text('Body Temperature', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                BodyTempGraph(data: bodyTemp),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HeartRateGraph extends StatelessWidget {
  final List<int> data;

  const HeartRateGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                    (index) => FlSpot(index.toDouble(), data[index].toDouble()),
              ),
              isCurved: true,
              color: Colors.red,
              belowBarData: BarAreaData(show: false),
            )
          ],
        ),
      ),
    );
  }
}

class SpO2Graph extends StatelessWidget {
  final List<int> data;

  const SpO2Graph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                    (index) => FlSpot(index.toDouble(), data[index].toDouble()),
              ),
              isCurved: true,
              color: Colors.blue,
              belowBarData: BarAreaData(show: false),
            )
          ],
        ),
      ),
    );
  }
}

class BodyTempGraph extends StatelessWidget {
  final List<double> data;

  const BodyTempGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                    (index) => FlSpot(index.toDouble(), data[index]),
              ),
              isCurved: true,
              color: Colors.orange,
              belowBarData: BarAreaData(show: false),
            )
          ],
        ),
      ),
    );
  }
}
