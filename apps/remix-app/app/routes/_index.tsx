import NxWelcome from '../nx-welcome';
import { useLoaderData } from '@remix-run/react';
import { json } from '@remix-run/node';
import { useEffect, useState } from 'react';

export const loader = async () => {
  const superSecret = process.env.SUPER_SECRET;
  const superSecretAlias = process.env.SUPER_SECRET_ALIAS;
  return json({ superSecret, superSecretAlias });
};

export default function Index() {
  const { superSecret, superSecretAlias } = useLoaderData<{
    superSecret: string;
    superSecretAlias: string;
  }>();

  // Fetching api data
  const [apiData, setApiData] = useState('');

  useEffect(() => {
    async function fetchData() {
      try {
        const response = await fetch('http://localhost:3000/');
        const result = await response.text();
        setApiData(result);
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    }

    fetchData();
  }, []);

  return (
    <div>
      <NxWelcome title={'remix-app'}>
        <>
          <br />
          <br />
          <span>SUPER_SECRET={superSecret}</span>
          <br />
          <br />
          <span>SUPER_SECRET_ALIAS={superSecretAlias}</span>
          <br />
          <br />
          <span>API_SUPER_SECRET={apiData}</span>
        </>
      </NxWelcome>
    </div>
  );
}
