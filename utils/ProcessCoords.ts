interface Post {
  postId: string;
  userId: string;
  content: string;
  mediaUrl: string;
  latitude: number;
  longitude: number;
  createdAt: Date;
}

type Coordinate = { latitude: number; longitude: number };
interface GroupedPost {
  latitude: number;
  longitude: number;
  groupedPosts: Post[];
}

function haversineDistance(coord1: Coordinate, coord2: Coordinate): number {
  const R = 6371; // Earth radius in kilometers
  const dLat = (coord2.latitude - coord1.latitude) * (Math.PI / 180);
  const dLon = (coord2.longitude - coord1.longitude) * (Math.PI / 180);

  const lat1 = coord1.latitude * (Math.PI / 180);
  const lat2 = coord2.latitude * (Math.PI / 180);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function averageCoordinates(posts: Post[]): Coordinate {
  const total = posts.reduce(
    (acc, post) => {
      acc.latitude += post.latitude;
      acc.longitude += post.longitude;
      return acc;
    },
    { latitude: 0, longitude: 0 }
  );
  return {
    latitude: total.latitude / posts.length,
    longitude: total.longitude / posts.length,
  };
}

export function groupSimilarPosts(
  posts: Post[],
  distanceThreshold: number
): GroupedPost[] {
  const groups: Post[][] = [];

  posts.forEach((post) => {
    let addedToGroup = false;

    for (const group of groups) {
      if (
        haversineDistance(
          { latitude: group[0].latitude, longitude: group[0].longitude },
          { latitude: post.latitude, longitude: post.longitude }
        ) <= distanceThreshold
      ) {
        group.push(post);
        addedToGroup = true;
        break;
      }
    }

    if (!addedToGroup) {
      groups.push([post]);
    }
  });

  return groups.map((group) => ({
    ...averageCoordinates(group),
    groupedPosts: group,
  }));
}
