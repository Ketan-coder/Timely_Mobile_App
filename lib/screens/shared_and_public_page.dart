import 'package:flutter/material.dart';

class SharedAndPublicPage extends StatefulWidget {
  const SharedAndPublicPage({super.key});

  @override
  State<SharedAndPublicPage> createState() => _SharedAndPublicPageState();
}

class _SharedAndPublicPageState extends State<SharedAndPublicPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: const [SharedTab(), PublicTab()],
          ),
          if (_isRefreshing) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: IconButton(
        onPressed: () {},
        icon: Icon(Icons.refresh),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.inverseSurface,
        child: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.surface,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          indicatorAnimation: TabIndicatorAnimation.elastic,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 15),
                    Text(
                      "Shared",
                      style: TextStyle(fontSize: 20, fontFamily: 'Sora'),
                    ),
                  ],
                ),
              ),
            ),
            Tab(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public),
                    SizedBox(width: 15),
                    Text(
                      "Public",
                      style: TextStyle(fontSize: 20, fontFamily: 'Sora'),
                    ),
                  ],
                ),
              ),
            ),
            //Tab(icon: Icon(Icons.public), text: "Public"),
          ],
        ),
      ),
    );
  }
}

class SharedTab extends StatefulWidget {
  const SharedTab({super.key});

  @override
  State<SharedTab> createState() => _SharedTabState();
}

class _SharedTabState extends State<SharedTab> {
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token; // Store token

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // setState(() {
          //   _titleOpacity = (1 - (scrollInfo.metrics.pixels / 100)).clamp(0, 1);
          // });
          return true;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              toolbarHeight: 80.0,
              flexibleSpace: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Center(
                            child: Text("Image failed to load"),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Opacity(
                      opacity: _titleOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Padding(
                          //  padding: const EdgeInsets.only(left: 1.0),
                          //  child: Icon(Icons.book,size: 40,color: Theme.of(context).colorScheme.primary),
                          // ),
                          Text(
                            "Shared\nNotebooks",
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.primary ??
                                  Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isRefreshing)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PublicTab extends StatefulWidget {
  const PublicTab({super.key});

  @override
  State<PublicTab> createState() => _PublicTabState();
}

class _PublicTabState extends State<PublicTab> {
  final double _titleOpacity = 1.0; // Controls title visibility
  bool _isRefreshing = false;
  String? _token; // Store token

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          // setState(() {
          //   _titleOpacity = (1 - (scrollInfo.metrics.pixels / 100)).clamp(0, 1);
          // });
          return true;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              toolbarHeight: 80.0,
              flexibleSpace: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: const Center(
                            child: Text("Image failed to load"),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Opacity(
                      opacity: _titleOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Padding(
                          //  padding: const EdgeInsets.only(left: 1.0),
                          //  child: Icon(Icons.book,size: 40,color: Theme.of(context).colorScheme.primary),
                          // ),
                          Text(
                            "Public\nNotebooks",
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.primary ??
                                  Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isRefreshing)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
